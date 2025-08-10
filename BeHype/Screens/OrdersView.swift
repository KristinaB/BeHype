//
//  OrdersView.swift
//  BeHype
//
//  Orders screen with filtering and status tracking for fills and open orders
//

import SwiftUI

struct OrdersView: View {
  @ObservedObject var hyperliquidService: HyperliquidService
  @State private var selectedFilter: OrderFilter = .all
  @State private var searchText = ""

  var body: some View {
    NavigationView {
      ZStack {
        Color.appBackground
          .ignoresSafeArea()

        VStack(spacing: 0) {
          // Filter and Search
          filterSection
          
          // Transaction List
          if filteredItems.isEmpty {
            emptyStateView
          } else {
            transactionsList
          }
        }
      }
      .navigationTitle("Orders")
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          IconButton(icon: "arrow.clockwise") {
            refreshData()
          }
        }
      }
    }
    .onAppear {
      refreshData()
    }
    .onChange(of: hyperliquidService.lastSwapResult) {
      refreshData()
    }
  }

  // MARK: - View Components

  private var filterSection: some View {
    VStack(spacing: 12) {
      // Filter Buttons
      AppCard {
        VStack(spacing: 12) {
          HStack {
            Text("Filter")
              .inputLabel()
            Spacer()
          }

          ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
              ForEach(OrderFilter.allCases, id: \.self) { filter in
                FilterButton(
                  title: filter.displayText,
                  isSelected: selectedFilter == filter
                ) {
                  selectedFilter = filter
                }
              }
            }
            .padding(.horizontal, 4)
          }
        }
      }
      .padding(.horizontal)
    }
  }

  private var transactionsList: some View {
    ScrollView {
      LazyVStack(spacing: 12) {
        ForEach(filteredItems, id: \.id) { item in
          switch item {
          case .fill(let fill):
            FillRow(fill: fill)
              .padding(.horizontal)
          case .openOrder(let order):
            OpenOrderRow(order: order, hyperliquidService: hyperliquidService)
              .padding(.horizontal)
          }
        }
      }
      .padding(.top, 16)
      .padding(.bottom, 120) // Ensure last item is visible above tab bar
      .padding(.horizontal, 0) // Remove any horizontal padding from scroll content
    }
  }

  private var emptyStateView: some View {
    VStack(spacing: 24) {
      Spacer()

      AppCard {
        VStack(spacing: 20) {
          Image(systemName: "tray")
            .font(.system(size: 50))
            .foregroundColor(.tertiaryText)

          VStack(spacing: 8) {
            Text(getEmptyStateTitle())
              .cardTitle()

            Text(getEmptyStateSubtitle())
              .secondaryText()
              .multilineTextAlignment(.center)
          }

          if selectedFilter == .all {
            SmallButton("Start Trading", icon: "plus.circle") {
              // Switch to trade tab (would need tab binding)
            }
          }
        }
        .padding(.vertical, 8)
      }

      Spacer()
    }
    .padding()
  }

  // MARK: - Transaction Item Types
  
  enum TransactionItem: Identifiable {
    case fill(UserFill)
    case openOrder(OpenOrder)
    
    var id: String {
      switch self {
      case .fill(let fill):
        return "fill_\(fill.hash)"
      case .openOrder(let order):
        return "order_\(order.oid)"
      }
    }
    
    var timestamp: UInt64 {
      switch self {
      case .fill(let fill):
        return fill.time
      case .openOrder(let order):
        return order.timestamp
      }
    }
  }

  // MARK: - Computed Properties

  private var filteredItems: [TransactionItem] {
    var items: [TransactionItem] = []
    
    // Add fills based on filter
    let fills = hyperliquidService.userFills.filter { fill in
      switch selectedFilter {
      case .all, .confirmed:
        return true
      case .open:
        return false  // Fills are never open
      case .failed:
        return false  // We only get successful fills
      case .buys:
        return fill.isBuy
      case .sells:
        return !fill.isBuy
      }
    }
    items.append(contentsOf: fills.map { TransactionItem.fill($0) })
    
    // Add open orders based on filter
    let orders = hyperliquidService.openOrders.filter { order in
      switch selectedFilter {
      case .all, .open:
        return true
      case .confirmed, .failed:
        return false  // Open orders are not confirmed or failed
      case .buys:
        return order.side == "B"
      case .sells:
        return order.side == "A"
      }
    }
    items.append(contentsOf: orders.map { TransactionItem.openOrder($0) })
    
    // Apply search filter
    let filtered = items.filter { item in
      if !searchText.isEmpty {
        let searchLower = searchText.lowercased()
        switch item {
        case .fill(let fill):
          return fill.displayCoin.lowercased().contains(searchLower) ||
                 fill.hash.lowercased().contains(searchLower) ||
                 fill.displaySide.lowercased().contains(searchLower)
        case .openOrder(let order):
          return order.displayCoin.lowercased().contains(searchLower) ||
                 String(order.oid).contains(searchLower) ||
                 order.displaySide.lowercased().contains(searchLower)
        }
      }
      return true
    }
    
    // Sort by timestamp (newest first)
    return filtered.sorted { $0.timestamp > $1.timestamp }
  }

  private var filteredFills: [UserFill] {
    let allFills = hyperliquidService.userFills

    let filtered = allFills.filter { fill in
      // Apply filter
      switch selectedFilter {
      case .all:
        break
      case .open:
        // For real fills, we only show completed ones, so skip open filter
        return false
      case .confirmed:
        // All fills are confirmed
        break
      case .failed:
        // For real fills, we only get successful ones, so skip failed filter
        return false
      case .buys:
        if !fill.isBuy { return false }
      case .sells:
        if fill.isBuy { return false }
      }

      // Apply search
      if !searchText.isEmpty {
        let searchLower = searchText.lowercased()
        return fill.displayCoin.lowercased().contains(searchLower)
          || fill.hash.lowercased().contains(searchLower)
          || fill.displaySide.lowercased().contains(searchLower)
      }

      return true
    }

    return filtered.sorted { $0.time > $1.time }
  }

  // MARK: - Private Methods
  
  private func refreshData() {
    hyperliquidService.fetchUserFills()
    hyperliquidService.fetchOpenOrders()
  }

  private func getEmptyStateTitle() -> String {
    switch selectedFilter {
    case .all:
      return "No Fills Yet"
    case .open:
      return "No Open Orders"
    case .confirmed:
      return "No Confirmed Fills"
    case .failed:
      return "No Failed Fills"
    case .buys:
      return "No Buy Fills"
    case .sells:
      return "No Sell Fills"
    }
  }

  private func getEmptyStateSubtitle() -> String {
    switch selectedFilter {
    case .all:
      return "Start trading to see your fill history here."
    case .open:
      return "No open orders found."
    case .confirmed:
      return "You don't have any confirmed fills yet."
    case .failed:
      return "No failed fills found."
    case .buys:
      return "You haven't made any buy orders yet."
    case .sells:
      return "You haven't made any sell orders yet."
    }
  }
}

// MARK: - Fill Row

struct FillRow: View {
  let fill: UserFill

  var body: some View {
    AppCard {
      HStack {
        // Fill Icon and Type
        VStack(spacing: 8) {
          ZStack {
            Circle()
              .fill((fill.isBuy ? Color.bullishGreen : Color.bearishRed).opacity(0.2))
              .frame(width: 40, height: 40)

            Image(systemName: fill.isBuy ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
              .font(.headline)
              .foregroundColor(fill.isBuy ? .bullishGreen : .bearishRed)
          }

          Text("FILLED")
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundColor(.bullishGreen)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
              RoundedRectangle(cornerRadius: 4)
                .fill(Color.bullishGreen.opacity(0.2))
            )
        }

        // Fill Details
        VStack(alignment: .leading, spacing: 8) {
          HStack {
            Text(fill.displayCoin)
              .cardTitle()

            Spacer()

            Text(fill.displaySide.uppercased())
              .font(.caption)
              .fontWeight(.bold)
              .foregroundColor(fill.isBuy ? .bullishGreen : .bearishRed)
          }

          HStack {
            VStack(alignment: .leading, spacing: 4) {
              Text("Size")
                .captionText()

              Text("\(fill.sz) \(fill.isBuy ? "USDC" : "BTC")")
                .secondaryText()
                .fontWeight(.medium)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
              Text("Price")
                .captionText()

              Text(fill.displayPrice)
                .secondaryText()
                .fontWeight(.medium)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
              Text("Value")
                .captionText()

              Text(formatFillValue())
                .priceText()
                .font(.subheadline)
            }
          }

          HStack {
            Text(fill.formattedDate)
              .captionText()

            Spacer()

            if let fee = fill.fee, let feeToken = fill.feeToken {
              Text("Fee: \(fee) \(feeToken)")
                .captionText()
            }
          }
        }
      }
    }
  }

  private func formatFillValue() -> String {
    let sizeValue = Double(fill.sz) ?? 0
    let priceValue = Double(fill.px) ?? 0

    if fill.isBuy {
      // For buy orders, show BTC received
      let btcReceived = sizeValue / priceValue
      return String(format: "%.6f BTC", btcReceived)
    } else {
      // For sell orders, show USDC received
      let usdcReceived = sizeValue * priceValue
      return String(format: "%.2f USDC", usdcReceived)
    }
  }
}

// MARK: - Open Order Row

struct OpenOrderRow: View {
  let order: OpenOrder
  @ObservedObject var hyperliquidService: HyperliquidService
  @State private var showingCancelConfirmation = false
  @State private var isCancelling = false
  
  var body: some View {
    AppCard {
      HStack {
        // Order Icon and Type
        VStack(spacing: 8) {
          ZStack {
            Circle()
              .fill(Color.primaryGradientStart.opacity(0.2))
              .frame(width: 40, height: 40)
            
            Image(systemName: "clock.fill")
              .font(.headline)
              .foregroundColor(.primaryGradientStart)
          }
          
          Text("OPEN")
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundColor(.primaryGradientStart)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
              RoundedRectangle(cornerRadius: 4)
                .fill(Color.primaryGradientStart.opacity(0.2))
            )
        }
        
        // Order Details
        VStack(alignment: .leading, spacing: 8) {
          HStack {
            Text(order.displayCoin)
              .cardTitle()
            
            Spacer()
            
            Text(order.displaySide.uppercased())
              .font(.caption)
              .fontWeight(.bold)
              .foregroundColor(order.side == "B" ? .bullishGreen : .bearishRed)
          }
          
          HStack {
            VStack(alignment: .leading, spacing: 4) {
              Text("Size")
                .captionText()
              
              Text("\(order.sz) \(order.side == "B" ? "USDC" : "BTC")")
                .secondaryText()
                .fontWeight(.medium)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
              Text("Limit Price")
                .captionText()
              
              Text("$\(order.limitPx)")
                .secondaryText()
                .fontWeight(.medium)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
              Text("Type")
                .captionText()
              
              Text(order.displayOrderType)
                .priceText()
                .font(.subheadline)
            }
          }
          
          HStack {
            Text(order.displayDate)
              .captionText()
            
            Spacer()
            
            Text("TIF: \(order.tif)")
              .captionText()
          }
          
          // Cancel Button
          HStack {
            Spacer()
            
            SmallButton(
              isCancelling ? "Cancelling..." : "Cancel Order", 
              icon: isCancelling ? "clock" : "xmark.circle"
            ) {
              showingCancelConfirmation = true
            }
            .disabled(isCancelling)
          }
          .padding(.top, 8)
        }
      }
    }
    .alert("Cancel Order", isPresented: $showingCancelConfirmation) {
      Button("Cancel", role: .cancel) { }
      Button("Confirm", role: .destructive) {
        performCancelOrder()
      }
    } message: {
      Text("Are you sure you want to cancel this order?")
    }
  }
  
  private func performCancelOrder() {
    isCancelling = true
    
    // Use the asset string directly (e.g., "@142" for BTC/USDC)
    let assetString = order.coin
    
    hyperliquidService.cancelOrder(asset: assetString, orderId: order.oid) { success, message in
      DispatchQueue.main.async {
        self.isCancelling = false
        
        if success {
          // Refresh data to remove cancelled order
          self.hyperliquidService.fetchOpenOrders()
        }
        // Could add toast notification here for user feedback
      }
    }
  }
}

// MARK: - Supporting Types

enum OrderFilter: CaseIterable {
  case all, open, confirmed, failed, buys, sells

  var displayText: String {
    switch self {
    case .all: return "All"
    case .open: return "Open"
    case .confirmed: return "Confirmed"
    case .failed: return "Failed"
    case .buys: return "Buys"
    case .sells: return "Sells"
    }
  }
}

#Preview {
  OrdersView(hyperliquidService: HyperliquidService())
}
