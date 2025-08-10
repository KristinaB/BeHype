//
//  TransactionsView.swift
//  BeHype
//
//  Transaction history screen with filtering and status tracking
//

import SwiftUI

struct TransactionsView: View {
  @ObservedObject var hyperliquidService: HyperliquidService
  @State private var selectedFilter: TransactionFilter = .all
  @State private var searchText = ""

  var body: some View {
    NavigationView {
      ZStack {
        Color.appBackground
          .ignoresSafeArea()

        VStack(spacing: 16) {
          // Filter and Search
          filterSection

          // Transaction List
          if filteredFills.isEmpty {
            emptyStateView
          } else {
            fillsList
          }
        }
      }
      .navigationTitle("Transactions")
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          IconButton(icon: "arrow.clockwise") {
            hyperliquidService.fetchUserFills()
          }
        }
      }
    }
    .onAppear {
      hyperliquidService.fetchUserFills()
    }
    .onChange(of: hyperliquidService.lastSwapResult) {
      hyperliquidService.fetchUserFills()
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
              ForEach(TransactionFilter.allCases, id: \.self) { filter in
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

  private var fillsList: some View {
    ScrollView {
      LazyVStack(spacing: 12) {
        ForEach(filteredFills, id: \.hash) { fill in
          FillRow(fill: fill)
            .padding(.horizontal)
        }
      }
      .padding(.vertical)
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

  // MARK: - Computed Properties

  private var filteredFills: [UserFill] {
    let allFills = hyperliquidService.userFills

    let filtered = allFills.filter { fill in
      // Apply filter
      switch selectedFilter {
      case .all:
        break
      case .pending:
        // For real fills, we only show completed ones, so skip pending filter
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

  private func getEmptyStateTitle() -> String {
    switch selectedFilter {
    case .all:
      return "No Fills Yet"
    case .pending:
      return "No Pending Fills"
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
    case .pending:
      return "All your fills have been processed."
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

// MARK: - Supporting Types

enum TransactionFilter: CaseIterable {
  case all, pending, confirmed, failed, buys, sells

  var displayText: String {
    switch self {
    case .all: return "All"
    case .pending: return "Pending"
    case .confirmed: return "Confirmed"
    case .failed: return "Failed"
    case .buys: return "Buys"
    case .sells: return "Sells"
    }
  }
}

#Preview {
  TransactionsView(hyperliquidService: HyperliquidService())
}
