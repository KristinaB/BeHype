//
//  TradingService.swift
//  BeHype
//
//  Service for managing trading operations and order placement
//

import Foundation
import SwiftUI

class TradingService: ObservableObject {
  @Published var isLoading: Bool = false
  @Published var status: String = ""
  @Published var lastSwapResult: String = ""

  private weak var walletService: WalletService?

  init(walletService: WalletService) {
    self.walletService = walletService
  }

  func performSwap() {
    guard let walletService = walletService,
      let walletClient = walletService.getWalletClient()
    else {
      status = "❌ Wallet not loaded"
      return
    }

    let usdcAmount = Double(walletService.usdcBalance) ?? 0
    guard usdcAmount >= 11.0 else {
      status = "❌ Insufficient USDC balance (need at least $11)"
      return
    }

    isLoading = true
    status = "🔄 Swapping $11 USDC to BTC..."

    DispatchQueue.global(qos: .background).async {
      let result = walletClient.swapUsdcToBtc(usdcAmount: "11.0")

      DispatchQueue.main.async {
        if result.success {
          var resultText = "✅ Swap successful!\n"
          resultText += "Message: \(result.message)\n"
          if let orderId = result.orderId {
            resultText += "Order ID: \(orderId)\n"
          }
          if let filledSize = result.filledSize {
            resultText += "Filled Size: \(filledSize)\n"
          }
          if let avgPrice = result.avgPrice {
            resultText += "Avg Price: \(avgPrice)"
          }

          self.status = "✅ Swap completed successfully"
          self.lastSwapResult = resultText
        } else {
          self.status = "❌ Swap failed: \(result.message)"
          self.lastSwapResult = "❌ Failed: \(result.message)"
        }
        self.isLoading = false
      }
    }
  }

  func placeLimitOrder(
    orderType: OrderType,
    amount: String,
    limitPrice: String,
    completion: @escaping (SwapResult) -> Void
  ) {
    print("📋 [TradingService] Placing \(orderType == .buy ? "BUY" : "SELL") limit order...")
    print(
      "📋 [TradingService] Amount: \(amount) \(orderType == .buy ? "USDC" : "BTC"), Price: $\(limitPrice)"
    )

    // Check if running in UI test mock mode
    if MockManager.shared.isUITestMockMode {
      print("🧪 [UI TEST] Using mock order placement")
      let mockResult = MockManager.shared.mockOrderPlacement(
        orderType: orderType,
        amount: amount,
        price: limitPrice
      )

      DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        self.status = mockResult.success ? "✅ Mock order placed" : "❌ Mock order failed"
        self.lastSwapResult = mockResult.message
        completion(mockResult)
      }
      return
    }

    guard let walletService = walletService,
      let walletClient = walletService.getWalletClient()
    else {
      completion(
        SwapResult(
          success: false,
          message: "❌ Wallet not loaded",
          orderId: nil,
          filledSize: nil,
          avgPrice: nil
        )
      )
      return
    }

    // Use real limit order methods from rebuilt framework
    print("🔄 [TradingService] Placing real limit order using Rust SDK...")

    isLoading = true
    status = "🔄 Placing \(orderType == .buy ? "buy" : "sell") limit order..."

    DispatchQueue.global(qos: .background).async {
      let result: SwapResult

      // Round price to proper tick size for BTC/USDC (@142)
      // BTC/USDC has $1.00 tick size based on testing
      let roundedLimitPrice = self.roundPriceToTickSize(price: limitPrice, tickSize: 1.0)
      print(
        "📏 [TradingService] Price rounded from $\(limitPrice) to $\(roundedLimitPrice) for tick size compliance"
      )

      // Round BTC amount to 5 decimal places for precision compliance
      let roundedBtcAmount = self.roundBtcAmount(amount: amount)
      print(
        "📏 [TradingService] BTC amount rounded from \(amount) to \(roundedBtcAmount) for precision compliance"
      )

      if orderType == .buy {
        // For buy orders, amount is in USDC, convert BTC at limit price
        result = walletClient.placeBtcBuyOrder(usdcAmount: amount, limitPrice: roundedLimitPrice)
      } else {
        // For sell orders, amount is in BTC, sell at limit price
        result = walletClient.placeBtcSellOrder(
          btcAmount: roundedBtcAmount, limitPrice: roundedLimitPrice)
      }

      DispatchQueue.main.async {
        self.isLoading = false

        if result.success {
          var resultText = "✅ \(orderType == .buy ? "Buy" : "Sell") order placed successfully!\n"
          resultText += "Message: \(result.message)\n"
          if let orderId = result.orderId {
            resultText += "Order ID: \(orderId)\n"
          }
          if let filledSize = result.filledSize {
            resultText += "Filled Size: \(filledSize)\n"
          }
          if let avgPrice = result.avgPrice {
            resultText += "Average Price: $\(avgPrice)\n"
          }

          self.status = resultText
          self.lastSwapResult = resultText

          // Refresh balance after successful order
          self.walletService?.checkBalance()
        } else {
          self.status = "❌ Order failed: \(result.message)"
          self.lastSwapResult = "❌ Failed: \(result.message)"
        }

        completion(result)
      }
    }
  }

  // Convenience methods for specific order types
  func placeBuyOrder(
    usdcAmount: String,
    limitPrice: String,
    completion: @escaping (SwapResult) -> Void
  ) {
    placeLimitOrder(
      orderType: .buy,
      amount: usdcAmount,
      limitPrice: limitPrice,
      completion: completion
    )
  }

  func placeSellOrder(
    btcAmount: String,
    limitPrice: String,
    completion: @escaping (SwapResult) -> Void
  ) {
    placeLimitOrder(
      orderType: .sell,
      amount: btcAmount,
      limitPrice: limitPrice,
      completion: completion
    )
  }

  // MARK: - Price and Amount Rounding Helper Methods

  private func roundPriceToTickSize(price: String, tickSize: Double) -> String {
    guard let priceDouble = Double(price) else { return price }
    let rounded = (priceDouble / tickSize).rounded() * tickSize
    return String(format: "%.0f", rounded)  // Format as whole dollars for $1 tick size
  }

  private func roundBtcAmount(amount: String) -> String {
    guard let amountDouble = Double(amount) else { return amount }
    let rounded = (amountDouble * 100_000).rounded() / 100_000  // Round to 5 decimal places
    return String(format: "%.5f", rounded)
  }
  
  // MARK: - Cancel Order Functionality
  
  func cancelOrder(asset: UInt32, orderId: UInt64, completion: @escaping (Bool, String) -> Void) {
    print("🚫 [TradingService] Starting cancelOrder for asset: \(asset), orderId: \(orderId)")
    
    guard let walletService = walletService,
          let walletClient = walletService.getWalletClient()
    else {
      print("❌ [TradingService] Wallet client not available")
      completion(false, "Wallet not loaded")
      return
    }
    
    isLoading = true
    status = "🚫 Cancelling order..."
    
    DispatchQueue.global(qos: .background).async {
      // Use bulk_cancel format: {"a": asset, "o": orderId}
      let result = walletClient.cancelOrder(asset: asset, orderId: orderId)
      
      DispatchQueue.main.async {
        self.isLoading = false
        
        if result.success {
          self.status = "✅ Order cancelled successfully"
          print("✅ [TradingService] Order cancelled: \(result.message)")
          completion(true, result.message)
        } else {
          self.status = "❌ Failed to cancel order"
          print("❌ [TradingService] Cancel failed: \(result.message)")
          completion(false, result.message)
        }
      }
    }
  }
}
