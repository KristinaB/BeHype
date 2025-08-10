//
//  MockManager.swift
//  BeHype
//
//  Created for UI Testing Support
//

import Foundation

class MockManager {
  static let shared = MockManager()

  private init() {}

  // Check if app is running in UI test mock mode
  var isUITestMockMode: Bool {
    return ProcessInfo.processInfo.arguments.contains("UITEST_MOCK_MODE")
  }

  // Mock responses for different operations
  struct MockResponses {
    static let successfulBuyOrder = SwapResult(
      success: true,
      message: "Buy order placed successfully",
      orderId: 130_243_366_999,
      filledSize: "0.00009",
      avgPrice: "118225"
    )

    static let successfulSellOrder = SwapResult(
      success: true,
      message: "Sell order filled",
      orderId: 130_243_367_000,
      filledSize: "0.00008",
      avgPrice: "118225"
    )

    static let insufficientBalanceError = SwapResult(
      success: false,
      message: "Insufficient balance",
      orderId: nil,
      filledSize: nil,
      avgPrice: nil
    )

    static let networkTimeoutError = SwapResult(
      success: false,
      message: "Network timeout - please try again",
      orderId: nil,
      filledSize: nil,
      avgPrice: nil
    )

    static let validationError = SwapResult(
      success: false,
      message: "Price must be divisible by tick size",
      orderId: nil,
      filledSize: nil,
      avgPrice: nil
    )
  }

  // Mock order placement based on input parameters
  func mockOrderPlacement(orderType: OrderType, amount: String, price: String) -> SwapResult {
    // Simulate different scenarios based on input

    // Mock insufficient balance for large orders
    if let amountDouble = Double(amount), amountDouble > 1000 {
      return MockResponses.insufficientBalanceError
    }

    // Mock validation error for zero price
    if price == "0" || price.isEmpty {
      return MockResponses.validationError
    }

    // Mock network timeout for specific test amounts
    if amount == "999" {
      return MockResponses.networkTimeoutError
    }

    // Default to successful order
    switch orderType {
    case .buy:
      return MockResponses.successfulBuyOrder
    case .sell:
      return MockResponses.successfulSellOrder
    }
  }

  // Generate mock transaction data for testing
  func generateMockTransactions() -> [UserFill] {
    let currentTime = UInt64(Date().timeIntervalSince1970 * 1000)

    return [
      UserFill(
        coin: "@142",
        px: "118225.0",
        sz: "0.00009",
        side: "B",
        time: currentTime - 3_600_000,  // 1 hour ago
        startPosition: "0.0",
        dir: "Buy",
        closedPnl: "0.0",
        hash: "0x123456789abcdef",
        oid: 130_243_366_999,
        crossed: false,
        fee: "0.50",
        tid: 1001,
        feeToken: "USDC"
      ),
      UserFill(
        coin: "@142",
        px: "118000.0",
        sz: "0.00008",
        side: "A",
        time: currentTime - 7_200_000,  // 2 hours ago
        startPosition: "0.00009",
        dir: "Sell",
        closedPnl: "2.25",
        hash: "0xfedcba987654321",
        oid: 130_243_367_000,
        crossed: false,
        fee: "0.48",
        tid: 1002,
        feeToken: "USDC"
      ),
    ]
  }
}
