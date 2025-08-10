import Foundation
import SwiftUI

// MARK: - Order Type Enum

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

// MARK: - Data Structures
// Note: Using SwapResult from the framework

class HyperliquidService: ObservableObject {
  // Service instances
  @Published var walletService: WalletService
  @Published var marketDataService: MarketDataService
  @Published var tradingService: TradingService
  @Published var transactionService: TransactionService

  // Computed properties for backward compatibility
  var status: String {
    return walletService.status.isEmpty ? marketDataService.status : walletService.status
  }

  var isLoading: Bool {
    return walletService.isLoading || marketDataService.isLoading || tradingService.isLoading
  }

  var exchangeAssets: Int {
    return marketDataService.exchangeAssets
  }

  var usdcBalance: String {
    return walletService.usdcBalance
  }

  var btcBalance: String {
    return walletService.btcBalance
  }

  var btcPrice: String {
    return marketDataService.btcPrice
  }

  var lastSwapResult: String {
    return tradingService.lastSwapResult
  }

  var userFills: [UserFill] {
    return transactionService.userFills
  }

  var walletAddress: String {
    return walletService.walletAddress
  }

  init() {
    let wallet = WalletService()
    self.walletService = wallet
    self.marketDataService = MarketDataService()
    self.tradingService = TradingService(walletService: wallet)
    self.transactionService = TransactionService(walletService: wallet)
  }

  func loadPrivateKey() {
    walletService.loadPrivateKey()
  }

  func fetchExchangeData() {
    marketDataService.fetchExchangeData()
  }

  func checkBalance() {
    walletService.checkBalance()
  }

  func performSwap() {
    tradingService.performSwap()
  }

  func getCandles(interval: String, hoursBack: Int) -> [CandleData] {
    return marketDataService.getCandles(interval: interval, hoursBack: hoursBack)
  }

  func getCandleData() {
    marketDataService.getCandleData()
  }

  func runFullDemo() {
    print("🚀 [HyperliquidService] Starting runFullDemo...")
    loadPrivateKey()

    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
      print("📊 [HyperliquidService] Running fetchExchangeData after 1s delay...")
      self.fetchExchangeData()
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
      print("💰 [HyperliquidService] Running checkBalance after 3s delay...")
      self.checkBalance()
    }
  }

  // MARK: - Trading Delegation Methods

  func placeLimitOrder(
    orderType: OrderType,
    amount: String,
    limitPrice: String,
    completion: @escaping (SwapResult) -> Void
  ) {
    tradingService.placeLimitOrder(
      orderType: orderType,
      amount: amount,
      limitPrice: limitPrice,
      completion: completion
    )
  }

  func placeBuyOrder(
    usdcAmount: String,
    limitPrice: String,
    completion: @escaping (SwapResult) -> Void
  ) {
    tradingService.placeBuyOrder(
      usdcAmount: usdcAmount,
      limitPrice: limitPrice,
      completion: completion
    )
  }

  func placeSellOrder(
    btcAmount: String,
    limitPrice: String,
    completion: @escaping (SwapResult) -> Void
  ) {
    tradingService.placeSellOrder(
      btcAmount: btcAmount,
      limitPrice: limitPrice,
      completion: completion
    )
  }

  // MARK: - Transaction Delegation Methods

  func fetchUserFills(daysBack: Int = 30) {
    transactionService.fetchUserFills(daysBack: daysBack)
  }
}
