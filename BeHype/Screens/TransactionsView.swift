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
    @State private var transactions: [Transaction] = []
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // Filter and Search
                    filterSection
                    
                    // Transaction List
                    if filteredTransactions.isEmpty {
                        emptyStateView
                    } else {
                        transactionList
                    }
                }
            }
            .navigationTitle("Transactions")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    IconButton(icon: "arrow.clockwise") {
                        refreshTransactions()
                    }
                }
            }
        }
        .onAppear {
            loadTransactions()
        }
        .onChange(of: hyperliquidService.lastSwapResult) {
            loadTransactions()
        }
    }
    
    // MARK: - View Components
    
    private var filterSection: some View {
        VStack(spacing: 12) {
            // Search Bar
            SearchTextField("Search transactions...", text: $searchText)
                .padding(.horizontal)
            
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
    
    private var transactionList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredTransactions) { transaction in
                    TransactionRow(transaction: transaction)
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
    
    private var filteredTransactions: [Transaction] {
        let filtered = transactions.filter { transaction in
            // Apply filter
            switch selectedFilter {
            case .all:
                break
            case .pending:
                if transaction.status != .pending { return false }
            case .confirmed:
                if transaction.status != .confirmed { return false }
            case .failed:
                if transaction.status != .failed { return false }
            case .buys:
                if transaction.type != .buy { return false }
            case .sells:
                if transaction.type != .sell { return false }
            }
            
            // Apply search
            if !searchText.isEmpty {
                let searchLower = searchText.lowercased()
                return transaction.pair.lowercased().contains(searchLower) ||
                       transaction.id.lowercased().contains(searchLower) ||
                       transaction.type.displayText.lowercased().contains(searchLower)
            }
            
            return true
        }
        
        return filtered.sorted { $0.timestamp > $1.timestamp }
    }
    
    // MARK: - Private Methods
    
    private func loadTransactions() {
        // Create sample transactions based on service state
        var sampleTransactions: [Transaction] = []
        
        // Add transaction from last swap result
        if !hyperliquidService.lastSwapResult.isEmpty {
            let isSuccess = hyperliquidService.lastSwapResult.contains("✅")
            sampleTransactions.append(
                Transaction(
                    id: "tx_\(Date().timeIntervalSince1970)",
                    pair: "BTC/USDC",
                    type: .buy,
                    amount: "11.00",
                    price: hyperliquidService.btcPrice,
                    total: "11.00",
                    status: isSuccess ? .confirmed : .failed,
                    timestamp: Date(),
                    fee: "0.05"
                )
            )
        }
        
        // Add some sample historical transactions
        let sampleData = [
            ("BTC/USDC", TransactionType.buy, "25.00", "45000.00", StatusType.confirmed, -3600),
            ("BTC/USDC", TransactionType.sell, "0.0005", "46000.00", StatusType.confirmed, -7200),
            ("BTC/USDC", TransactionType.buy, "50.00", "44500.00", StatusType.pending, -10800),
            ("BTC/USDC", TransactionType.buy, "15.00", "45200.00", StatusType.failed, -14400)
        ]
        
        for (index, data) in sampleData.enumerated() {
            sampleTransactions.append(
                Transaction(
                    id: "tx_sample_\(index)",
                    pair: data.0,
                    type: data.1,
                    amount: data.2,
                    price: data.3,
                    total: calculateTotal(amount: data.2, price: data.3, type: data.1),
                    status: data.4,
                    timestamp: Date().addingTimeInterval(TimeInterval(data.5)),
                    fee: "0.05"
                )
            )
        }
        
        transactions = sampleTransactions
    }
    
    private func refreshTransactions() {
        loadTransactions()
    }
    
    private func calculateTotal(amount: String, price: String, type: TransactionType) -> String {
        let amountValue = Double(amount) ?? 0
        let priceValue = Double(price) ?? 0
        
        if type == .buy {
            return String(format: "%.2f", amountValue)
        } else {
            return String(format: "%.2f", amountValue * priceValue)
        }
    }
    
    private func getEmptyStateTitle() -> String {
        switch selectedFilter {
        case .all:
            return "No Transactions Yet"
        case .pending:
            return "No Pending Transactions"
        case .confirmed:
            return "No Confirmed Transactions"
        case .failed:
            return "No Failed Transactions"
        case .buys:
            return "No Buy Orders"
        case .sells:
            return "No Sell Orders"
        }
    }
    
    private func getEmptyStateSubtitle() -> String {
        switch selectedFilter {
        case .all:
            return "Start trading to see your transaction history here."
        case .pending:
            return "All your transactions have been processed."
        case .confirmed:
            return "You don't have any confirmed transactions yet."
        case .failed:
            return "No failed transactions found."
        case .buys:
            return "You haven't made any buy orders yet."
        case .sells:
            return "You haven't made any sell orders yet."
        }
    }
}

// MARK: - Transaction Row

struct TransactionRow: View {
    let transaction: Transaction
    
    var body: some View {
        AppCard {
            HStack {
                // Transaction Icon and Type
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(transaction.type.color.opacity(0.2))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: transaction.type.icon)
                            .font(.headline)
                            .foregroundColor(transaction.type.color)
                    }
                    
                    Text(transaction.status.displayText)
                        .statusText(status: transaction.status)
                }
                
                // Transaction Details
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(transaction.pair)
                            .cardTitle()
                        
                        Spacer()
                        
                        Text(transaction.type.displayText.uppercased())
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(transaction.type.color)
                    }
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Amount")
                                .captionText()
                            
                            Text("\(transaction.amount) \(transaction.type == .buy ? "USDC" : "BTC")")
                                .secondaryText()
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Price")
                                .captionText()
                            
                            Text("$\(transaction.price)")
                                .secondaryText()
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(transaction.type == .buy ? "Receive" : "Total")
                                .captionText()
                            
                            Text(formatTransactionValue())
                                .priceText()
                                .font(.subheadline)
                        }
                    }
                    
                    HStack {
                        Text(formatTimestamp(transaction.timestamp))
                            .captionText()
                        
                        Spacer()
                        
                        if let fee = transaction.fee {
                            Text("Fee: $\(fee)")
                                .captionText()
                        }
                    }
                }
            }
        }
    }
    
    private func formatTransactionValue() -> String {
        if transaction.type == .buy {
            let amount = Double(transaction.amount) ?? 0
            let price = Double(transaction.price) ?? 0
            let btcReceived = amount / price
            return String(format: "%.6f BTC", btcReceived)
        } else {
            return "$\(transaction.total)"
        }
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
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

enum TransactionType: CaseIterable {
    case buy, sell
    
    var displayText: String {
        switch self {
        case .buy: return "Buy"
        case .sell: return "Sell"
        }
    }
    
    var icon: String {
        switch self {
        case .buy: return "arrow.up.circle.fill"
        case .sell: return "arrow.down.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .buy: return .bullishGreen
        case .sell: return .bearishRed
        }
    }
}

struct Transaction: Identifiable {
    let id: String
    let pair: String
    let type: TransactionType
    let amount: String
    let price: String
    let total: String
    let status: StatusType
    let timestamp: Date
    let fee: String?
}

#Preview {
    TransactionsView(hyperliquidService: HyperliquidService())
}