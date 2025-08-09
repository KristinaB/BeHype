//
//  BeHypeUITests.swift
//  BeHypeUITests
//
//  Created by Kristina Canessa on 06/08/2025.
//

import XCTest

final class BeHypeUITests: XCTestCase {

  override func setUpWithError() throws {
    continueAfterFailure = false
  }

  override func tearDownWithError() throws {
    // Put teardown code here
  }

  // MARK: - Main UI Flow Test

  @MainActor
  func testCompleteUIFlow() throws {
    let app = XCUIApplication()
    app.launch()

    // Test Home Screen
    testHomeScreen(app)

    // Test Trade Screen
    testTradeScreen(app)

    // Test Transactions Screen
    testTransactionsScreen(app)

    // Test Chart Navigation from Home
    testChartFromHome(app)
  }

  // MARK: - Individual Screen Tests

  private func testHomeScreen(_ app: XCUIApplication) {
    // Wait for Home tab to be loaded
    let homeTab = app.tabBars.buttons["Home"]
    XCTAssertTrue(homeTab.waitForExistence(timeout: 2), "Home tab should exist")

    // Wait for navigation bar to be rendered
    XCTAssertTrue(app.navigationBars.element.waitForExistence(timeout: 1), "Navigation bar should exist")
    
    // Wait for branding text to be rendered
    XCTAssertTrue(app.staticTexts["BeHype"].waitForExistence(timeout: 1), "BeHype branding should exist")
    
    // Wait for Fund Wallet button to be rendered
    XCTAssertTrue(app.buttons["Fund Wallet"].waitForExistence(timeout: 1), "Fund Wallet button should exist")

    // Wait for key section headers
    XCTAssertTrue(app.staticTexts["Markets"].waitForExistence(timeout: 1), "Markets section should exist")

    // Wait for portfolio cards to be rendered
    XCTAssertTrue(app.staticTexts["USDC Balance"].waitForExistence(timeout: 1), "USDC Balance card should exist")
    XCTAssertTrue(
      app.staticTexts["Total Portfolio Value"].waitForExistence(timeout: 1), "Total Portfolio Value card should exist")

    // Wait for market data to be rendered
    XCTAssertTrue(app.staticTexts["BTC/USDC"].waitForExistence(timeout: 1), "BTC/USDC market should exist")
    
    // Wait for View Chart button to be rendered
    XCTAssertTrue(app.buttons["View Chart"].waitForExistence(timeout: 1), "View Chart button should exist")
  }

  private func testTradeScreen(_ app: XCUIApplication) {
    // Navigate to Trade tab
    let tradeTab = app.tabBars.buttons["Trade"]
    XCTAssertTrue(tradeTab.waitForExistence(timeout: 1), "Trade tab should exist")
    tradeTab.tap()

    // Wait for Trade screen to load
    XCTAssertTrue(
      app.navigationBars["Trade"].waitForExistence(timeout: 2), "Trade navigation should exist")

    // Wait for trading pair header to be rendered
    XCTAssertTrue(app.staticTexts["BTC/USDC"].waitForExistence(timeout: 1), "Trading pair should be displayed")
    XCTAssertTrue(app.staticTexts["24h Volume"].waitForExistence(timeout: 1), "24h Volume label should exist")

    // Wait for order type selector to be rendered
    XCTAssertTrue(app.staticTexts["Order Type"].waitForExistence(timeout: 1), "Order Type section should exist")
    XCTAssertTrue(app.buttons["BUY"].waitForExistence(timeout: 1), "BUY button should exist")
    XCTAssertTrue(app.buttons["SELL"].waitForExistence(timeout: 1), "SELL button should exist")

    // Wait for form fields to be rendered (without interacting)
    XCTAssertTrue(app.staticTexts["Amount"].waitForExistence(timeout: 1), "Amount label should exist")
    XCTAssertTrue(app.staticTexts["Limit Price"].waitForExistence(timeout: 1), "Limit Price label should exist")

    // Wait for order summary section to be rendered
    XCTAssertTrue(app.staticTexts["Order Summary"].waitForExistence(timeout: 1), "Order Summary section should exist")

    // Check for either "Estimated Receive" (buy) or "Estimated Value" (sell) - wait for at least one
    let estimatedReceiveExists = app.staticTexts["Estimated Receive"].waitForExistence(timeout: 1)
    let estimatedValueExists = app.staticTexts["Estimated Value"].waitForExistence(timeout: 1)
    XCTAssertTrue(
      estimatedReceiveExists || estimatedValueExists,
      "Should have either Estimated Receive or Estimated Value")

    XCTAssertTrue(app.staticTexts["Est. Fees"].waitForExistence(timeout: 1), "Est. Fees should exist")
  }

  private func testTransactionsScreen(_ app: XCUIApplication) {
    // Navigate to Transactions tab
    let transactionsTab = app.tabBars.buttons["Transactions"]
    XCTAssertTrue(transactionsTab.waitForExistence(timeout: 1), "Transactions tab should exist")
    transactionsTab.tap()

    // Wait for Transactions screen to load
    XCTAssertTrue(
      app.navigationBars["Transactions"].waitForExistence(timeout: 2),
      "Transactions navigation should exist")

    // Wait for filter buttons to be rendered
    XCTAssertTrue(app.buttons["All"].waitForExistence(timeout: 1), "All filter should exist")
    XCTAssertTrue(app.buttons["Pending"].waitForExistence(timeout: 1), "Pending filter should exist")
    XCTAssertTrue(app.buttons["Confirmed"].waitForExistence(timeout: 1), "Confirmed filter should exist")
    XCTAssertTrue(app.buttons["Failed"].waitForExistence(timeout: 1), "Failed filter should exist")
    XCTAssertTrue(app.buttons["Buys"].waitForExistence(timeout: 1), "Buys filter should exist")
    XCTAssertTrue(app.buttons["Sells"].waitForExistence(timeout: 1), "Sells filter should exist")

    // Wait for search field to be rendered
    XCTAssertTrue(
      app.textFields["Search transactions..."].waitForExistence(timeout: 1),
      "Search field should exist")

    // Wait for either empty state or transaction list to be rendered
    let hasEmptyState = app.staticTexts["No Transactions Yet"].waitForExistence(timeout: 1)
    let hasTransactionList = app.staticTexts["BTC/USDC"].waitForExistence(timeout: 1)
    XCTAssertTrue(
      hasEmptyState || hasTransactionList, "Should show either empty state or transactions")
  }

  private func testChartFromHome(_ app: XCUIApplication) {
    // Go back to Home tab
    let homeTab = app.tabBars.buttons["Home"]
    homeTab.tap()

    // Wait for home screen - navigation bar has no title
    XCTAssertTrue(
      app.navigationBars.element.waitForExistence(timeout: 1), "Home should be loaded")

    // Find and tap "View Chart" button
    let viewChartButton = app.buttons["View Chart"]
    XCTAssertTrue(viewChartButton.waitForExistence(timeout: 1), "View Chart button should exist")
    viewChartButton.tap()

    // Wait for chart sheet to appear
    XCTAssertTrue(
      app.navigationBars["BTC/USDC Chart"].waitForExistence(timeout: 2), "Chart should open")

    // Wait for chart elements to be rendered
    XCTAssertTrue(app.staticTexts["BTC/USDC"].waitForExistence(timeout: 1), "Chart title should exist")
    XCTAssertTrue(app.staticTexts["Spot Market"].waitForExistence(timeout: 1), "Spot Market label should exist")
    XCTAssertTrue(app.staticTexts["Timeframe"].waitForExistence(timeout: 1), "Timeframe section should exist")

    // Wait for timeframe buttons to be rendered (but don't tap them)
    XCTAssertTrue(app.buttons["15M"].waitForExistence(timeout: 1), "15M timeframe should exist")
    XCTAssertTrue(app.buttons["1H"].waitForExistence(timeout: 1), "1H timeframe should exist")
    XCTAssertTrue(app.buttons["4H"].waitForExistence(timeout: 1), "4H timeframe should exist")
    XCTAssertTrue(app.buttons["1D"].waitForExistence(timeout: 1), "1D timeframe should exist")

    // Verify chart info - check for any chart-related text
    let hasChartData = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'candles' OR label CONTAINS 'Loading' OR label CONTAINS 'chart'")).count > 0
    XCTAssertTrue(hasChartData, "Chart should show some chart-related info")

    // Close chart by tapping Done
    let doneButton = app.navigationBars.buttons["Done"]
    XCTAssertTrue(doneButton.waitForExistence(timeout: 1), "Done button should exist")
    doneButton.tap()

    // Verify we're back to home - navigation bar has no title
    XCTAssertTrue(
      app.navigationBars.element.waitForExistence(timeout: 1), "Should return to home")
  }
}
