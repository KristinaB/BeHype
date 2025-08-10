//
//  TradeView.swift
//  BeHype
//
//  Trading screen with limit order entry form
//

import SwiftUI

struct TradeView: View {
    @ObservedObject var hyperliquidService: HyperliquidService
    @State private var orderType: OrderType = .buy
    @State private var amount = ""
    @State private var limitPrice = ""
    @State private var showingOrderConfirmation = false
    @State private var showingChart = false
    
    private let pair = "BTC/USDC"
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Trading Pair Header
                        tradingPairHeader
                        
                        // Order Type Selector
                        orderTypeSelector
                        
                        // Order Form
                        orderForm
                        
                        // Order Summary
                        orderSummary
                        
                        // Place Order Button
                        placeOrderButton
                        
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
            .navigationTitle("Trade")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    IconButton(icon: "chart.xyaxis.line") {
                        showingChart.toggle()
                    }
                }
            }
            .sheet(isPresented: $showingChart) {
                ChartView(pair: pair)
            }
            .sheet(isPresented: $showingOrderConfirmation) {
                OrderConfirmationView(
                    orderType: orderType,
                    pair: pair,
                    amount: amount,
                    limitPrice: limitPrice,
                    estimatedValue: calculateEstimatedValue(),
                    hyperliquidService: hyperliquidService
                )
            }
        }
        .onAppear {
            loadMarketData()
        }
    }
    
    // MARK: - View Components
    
    private var tradingPairHeader: some View {
        AppCard {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(pair)
                            .sectionTitle()
                        
                        HStack(spacing: 12) {
                            Text("$\(hyperliquidService.btcPrice)")
                                .largePriceText()
                            
                            Text("+2.1%")
                                .priceText(color: .bullishGreen)
                                .font(.subheadline)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 8) {
                        Text("24h Volume")
                            .captionText()
                        
                        Text("$2.4M")
                            .secondaryText()
                            .fontWeight(.medium)
                    }
                }
                
                HStack {
                    InfoRow(title: "24h High", value: "$\(getHighPrice())")
                    InfoRow(title: "24h Low", value: "$\(getLowPrice())")
                }
            }
        }
    }
    
    private var orderTypeSelector: some View {
        AppCard {
            VStack(spacing: 16) {
                Text("Order Type")
                    .inputLabel()
                
                HStack(spacing: 8) {
                    Button(action: { orderType = .buy }) {
                        Text("BUY")
                            .smallButtonText()
                            .foregroundColor(orderType == .buy ? .bullishGreen : .secondaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.inputBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(
                                        orderType == .buy
                                            ? LinearGradient(
                                                colors: [.bullishGreen, .bullishGreen.opacity(0.6)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                            : LinearGradient(
                                                colors: [Color.borderGray.opacity(0.3)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            ),
                                        lineWidth: orderType == .buy ? 2 : 1
                                    )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: { orderType = .sell }) {
                        Text("SELL")
                            .smallButtonText()
                            .foregroundColor(orderType == .sell ? .bearishRed : .secondaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.inputBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(
                                        orderType == .sell
                                            ? LinearGradient(
                                                colors: [.bearishRed, .bearishRed.opacity(0.6)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                            : LinearGradient(
                                                colors: [Color.borderGray.opacity(0.3)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            ),
                                        lineWidth: orderType == .sell ? 2 : 1
                                    )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    private var orderForm: some View {
        VStack(spacing: 16) {
            // Amount Input
            InputCard(title: "Amount") {
                AmountTextField(
                    "Enter amount",
                    symbol: orderType == .buy ? "USDC" : "BTC",
                    amount: $amount,
                    balance: getBalanceText(),
                    onMaxTapped: {
                        setMaxAmount()
                    }
                )
            }
            
            // Limit Price Input
            InputCard(title: "Limit Price") {
                PriceTextField(
                    "Enter limit price",
                    price: $limitPrice,
                    marketPrice: hyperliquidService.btcPrice,
                    onMarketTapped: {
                        limitPrice = hyperliquidService.btcPrice
                    }
                )
            }
        }
    }
    
    private var orderSummary: some View {
        AppCard {
            VStack(spacing: 12) {
                Text("Order Summary")
                    .cardTitle()
                
                VStack(spacing: 8) {
                    InfoRow(
                        title: "Type",
                        value: "\(orderType.displayText) \(pair)",
                        color: orderType == .buy ? .bullishGreen : .bearishRed
                    )
                    
                    InfoRow(
                        title: "Amount",
                        value: "\(amount) \(orderType == .buy ? "USDC" : "BTC")"
                    )
                    
                    InfoRow(
                        title: "Limit Price",
                        value: "$\(limitPrice)"
                    )
                    
                    InfoRow(
                        title: "Estimated \(orderType == .buy ? "Receive" : "Value")",
                        value: calculateEstimatedValue(),
                        color: .primaryGradientStart
                    )
                    
                    InfoRow(
                        title: "Est. Fees",
                        value: "~$0.05"
                    )
                }
            }
        }
    }
    
    private var placeOrderButton: some View {
        VStack(spacing: 12) {
            PrimaryButton(
                "\(orderType.displayText.uppercased()) \(pair)",
                isLoading: hyperliquidService.isLoading,
                isDisabled: !isValidOrder()
            ) {
                if orderType == .buy && amount == "11.0" {
                    // Use existing swap functionality for $11 USDC → BTC
                    hyperliquidService.performSwap()
                } else {
                    showingOrderConfirmation.toggle()
                }
            }
            
            Text("⚠️ Trading with real funds on mainnet")
                .captionText()
                .foregroundColor(.warningOrange)
        }
    }
    
    // MARK: - Private Methods
    
    private func loadMarketData() {
        if hyperliquidService.btcPrice.isEmpty || hyperliquidService.btcPrice == "0.0" {
            hyperliquidService.fetchExchangeData()
        }
        
        if hyperliquidService.usdcBalance == "0.0" {
            hyperliquidService.checkBalance()
        }
        
        // Set default limit price to current market price
        if limitPrice.isEmpty && !hyperliquidService.btcPrice.isEmpty {
            limitPrice = hyperliquidService.btcPrice
        }
    }
    
    private func getBalanceText() -> String {
        if orderType == .buy {
            return hyperliquidService.usdcBalance + " USDC"
        } else {
            return hyperliquidService.btcBalance + " BTC"
        }
    }
    
    private func setMaxAmount() {
        if orderType == .buy {
            amount = hyperliquidService.usdcBalance
        } else {
            amount = hyperliquidService.btcBalance
        }
    }
    
    private func getHighPrice() -> String {
        let current = Double(hyperliquidService.btcPrice) ?? 0
        return String(format: "%.2f", current * 1.025)
    }
    
    private func getLowPrice() -> String {
        let current = Double(hyperliquidService.btcPrice) ?? 0
        return String(format: "%.2f", current * 0.975)
    }
    
    private func calculateEstimatedValue() -> String {
        guard let amountValue = Double(amount),
              let priceValue = Double(limitPrice),
              amountValue > 0, priceValue > 0 else {
            return "0.00"
        }
        
        if orderType == .buy {
            // Buying BTC with USDC
            let btcAmount = amountValue / priceValue
            return String(format: "%.6f BTC", btcAmount)
        } else {
            // Selling BTC for USDC
            let usdcValue = amountValue * priceValue
            return String(format: "%.2f USDC", usdcValue)
        }
    }
    
    private func isValidOrder() -> Bool {
        guard let amountValue = Double(amount),
              let priceValue = Double(limitPrice),
              amountValue > 0, priceValue > 0 else {
            return false
        }
        
        if orderType == .buy {
            let balance = Double(hyperliquidService.usdcBalance) ?? 0
            return amountValue <= balance
        } else {
            let btcBalance = Double(hyperliquidService.btcBalance) ?? 0
            return amountValue <= btcBalance
        }
    }
}

// MARK: - Order Type

enum OrderType: CaseIterable {
    case buy, sell
    
    var displayText: String {
        switch self {
        case .buy:
            return "Buy"
        case .sell:
            return "Sell"
        }
    }
}

// MARK: - Chart View

struct ChartView: View {
    let pair: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                VStack {
                    Text("Chart data will be implemented here")
                        .secondaryText()
                        .multilineTextAlignment(.center)
                    
                    Text("Currently showing: \(pair)")
                        .captionText()
                }
            }
            .navigationTitle("Chart")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Order Confirmation View

struct OrderConfirmationView: View {
    let orderType: OrderType
    let pair: String
    let amount: String
    let limitPrice: String
    let estimatedValue: String
    @ObservedObject var hyperliquidService: HyperliquidService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    AppCard {
                        VStack(spacing: 16) {
                            Text("Confirm Order")
                                .sectionTitle()
                            
                            VStack(spacing: 12) {
                                InfoRow(
                                    title: "Type",
                                    value: "\(orderType.displayText) \(pair)",
                                    color: orderType == .buy ? .bullishGreen : .bearishRed
                                )
                                
                                InfoRow(title: "Amount", value: amount)
                                InfoRow(title: "Limit Price", value: "$\(limitPrice)")
                                InfoRow(title: "Estimated", value: estimatedValue)
                            }
                        }
                    }
                    
                    VStack(spacing: 12) {
                        PrimaryButton("Confirm Order", isLoading: hyperliquidService.isLoading) {
                            // Simulate order placement
                            dismiss()
                        }
                        
                        SecondaryButton("Cancel") {
                            dismiss()
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Confirm")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    TradeView(hyperliquidService: HyperliquidService())
}