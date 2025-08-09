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
        XCTAssertTrue(homeTab.waitForExistence(timeout: 5), "Home tab should exist")
        
        // Verify main elements are present
        XCTAssertTrue(app.navigationBars["BeHype"].exists, "Home navigation title should be BeHype")
        
        // Check for key section headers
        XCTAssertTrue(app.staticTexts["Portfolio"].waitForExistence(timeout: 3), "Portfolio section should exist")
        XCTAssertTrue(app.staticTexts["Markets"].exists, "Markets section should exist")
        XCTAssertTrue(app.staticTexts["Quick Actions"].exists, "Quick Actions section should exist")
        XCTAssertTrue(app.staticTexts["System Status"].exists, "System Status section should exist")
        
        // Verify portfolio cards
        XCTAssertTrue(app.staticTexts["USDC Balance"].exists, "USDC Balance card should exist")
        XCTAssertTrue(app.staticTexts["Total Portfolio Value"].exists, "Total Portfolio Value card should exist")
        
        // Verify market data
        XCTAssertTrue(app.staticTexts["BTC/USDC"].exists, "BTC/USDC market should exist")
        XCTAssertTrue(app.staticTexts["Exchange Assets"].exists, "Exchange Assets should exist")
    }
    
    private func testTradeScreen(_ app: XCUIApplication) {
        // Navigate to Trade tab
        let tradeTab = app.tabBars.buttons["Trade"]
        XCTAssertTrue(tradeTab.exists, "Trade tab should exist")
        tradeTab.tap()
        
        // Wait for Trade screen to load
        XCTAssertTrue(app.navigationBars["Trade"].waitForExistence(timeout: 3), "Trade navigation should exist")
        
        // Verify trading pair header
        XCTAssertTrue(app.staticTexts["BTC/USDC"].exists, "Trading pair should be displayed")
        XCTAssertTrue(app.staticTexts["24h Volume"].exists, "24h Volume label should exist")
        
        // Verify order type selector
        XCTAssertTrue(app.staticTexts["Order Type"].exists, "Order Type section should exist")
        XCTAssertTrue(app.buttons["BUY"].exists, "BUY button should exist")
        XCTAssertTrue(app.buttons["SELL"].exists, "SELL button should exist")
        
        // Verify form fields (without interacting)
        XCTAssertTrue(app.staticTexts["Amount"].exists, "Amount label should exist")
        XCTAssertTrue(app.staticTexts["Limit Price"].exists, "Limit Price label should exist")
        
        // Verify order summary section
        XCTAssertTrue(app.staticTexts["Order Summary"].exists, "Order Summary section should exist")
        
        // Check for either "Estimated Receive" (buy) or "Estimated Value" (sell)
        let hasEstimatedReceive = app.staticTexts["Estimated Receive"].exists
        let hasEstimatedValue = app.staticTexts["Estimated Value"].exists
        XCTAssertTrue(hasEstimatedReceive || hasEstimatedValue, "Should have either Estimated Receive or Estimated Value")
        
        XCTAssertTrue(app.staticTexts["Est. Fees"].exists, "Est. Fees should exist")
    }
    
    private func testTransactionsScreen(_ app: XCUIApplication) {
        // Navigate to Transactions tab
        let transactionsTab = app.tabBars.buttons["Transactions"]
        XCTAssertTrue(transactionsTab.exists, "Transactions tab should exist")
        transactionsTab.tap()
        
        // Wait for Transactions screen to load
        XCTAssertTrue(app.navigationBars["Transactions"].waitForExistence(timeout: 3), "Transactions navigation should exist")
        
        // Verify filter buttons
        XCTAssertTrue(app.buttons["All"].exists, "All filter should exist")
        XCTAssertTrue(app.buttons["Pending"].exists, "Pending filter should exist")
        XCTAssertTrue(app.buttons["Confirmed"].exists, "Confirmed filter should exist")
        XCTAssertTrue(app.buttons["Failed"].exists, "Failed filter should exist")
        XCTAssertTrue(app.buttons["Buys"].exists, "Buys filter should exist")
        XCTAssertTrue(app.buttons["Sells"].exists, "Sells filter should exist")
        
        // Verify search field exists
        XCTAssertTrue(app.textFields.containing(.staticText, identifier: "Search transactions...").element.exists, 
                     "Search field should exist")
        
        // Should show either empty state or transaction list
        let hasEmptyState = app.staticTexts["No Transactions"].exists
        let hasTransactionList = app.staticTexts.matching(identifier: "BTC").count > 0
        XCTAssertTrue(hasEmptyState || hasTransactionList, "Should show either empty state or transactions")
    }
    
    private func testChartFromHome(_ app: XCUIApplication) {
        // Go back to Home tab
        let homeTab = app.tabBars.buttons["Home"]
        homeTab.tap()
        
        // Wait for home screen
        XCTAssertTrue(app.navigationBars["BeHype"].waitForExistence(timeout: 3), "Home should be loaded")
        
        // Find and tap "View Chart" button
        let viewChartButton = app.buttons["View Chart"]
        XCTAssertTrue(viewChartButton.waitForExistence(timeout: 3), "View Chart button should exist")
        viewChartButton.tap()
        
        // Wait for chart sheet to appear
        XCTAssertTrue(app.navigationBars["BTC/USDC Chart"].waitForExistence(timeout: 5), "Chart should open")
        
        // Verify chart elements
        XCTAssertTrue(app.staticTexts["BTC/USDC"].exists, "Chart title should exist")
        XCTAssertTrue(app.staticTexts["Spot Market"].exists, "Spot Market label should exist")
        XCTAssertTrue(app.staticTexts["Timeframe"].exists, "Timeframe section should exist")
        
        // Verify timeframe buttons exist (but don't tap them)
        XCTAssertTrue(app.buttons["15M"].exists, "15M timeframe should exist")
        XCTAssertTrue(app.buttons["1H"].exists, "1H timeframe should exist") 
        XCTAssertTrue(app.buttons["4H"].exists, "4H timeframe should exist")
        XCTAssertTrue(app.buttons["1D"].exists, "1D timeframe should exist")
        
        // Verify chart info
        let chartInfo = app.staticTexts.containing(.staticText, identifier: "candles").element
        XCTAssertTrue(chartInfo.exists, "Chart should show candle count info")
        
        // Close chart by tapping Done
        let doneButton = app.navigationBars.buttons["Done"]
        XCTAssertTrue(doneButton.exists, "Done button should exist")
        doneButton.tap()
        
        // Verify we're back to home
        XCTAssertTrue(app.navigationBars["BeHype"].waitForExistence(timeout: 3), "Should return to home")
    }
    
    // MARK: - Performance Test
    
    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
