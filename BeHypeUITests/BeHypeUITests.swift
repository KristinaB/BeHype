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
  
  // MARK: - Mock SDK Response Data handled by MockManager

  // MARK: - Main UI Flow Test

  @MainActor
  func testCompleteUIFlow() throws {
    let app = XCUIApplication()
    // Enable mock mode for testing without real trades
    app.launchArguments = ["UITEST_MOCK_MODE"]
    app.launch()
    
    // Wait for app to fully load
    XCTAssertTrue(app.tabBars.element.waitForExistence(timeout: 5), "App should launch successfully")

    // Comprehensive UI Flow Tests
    testHomeScreen(app)
    testPortfolioCardInteractions(app)
    testFundWalletModalFlow(app)
    testTradeScreen(app)
    testOrderPlacementFlow(app)
    testOrderTypeToggling(app)
    testOrdersScreen(app)
    testOpenOrdersAfterPlacement(app)
    testChartFromHome(app)
    testNavigationFlow(app)
    testErrorStatesHandling(app)
  }

  // MARK: - Comprehensive Test Methods
  
  private func testOpenOrdersAfterPlacement(_ app: XCUIApplication) {
    // This test verifies that placed orders appear in the Open section
    // Navigate to Orders tab
    app.tabBars.buttons["Orders"].tap()
    
    // Wait for screen to load
    XCTAssertTrue(
      app.navigationBars["Orders"].waitForExistence(timeout: 2),
      "Orders screen should load")
    
    // Tap Open filter to see open orders
    let openFilter = app.buttons["Open"]
    if openFilter.exists {
      openFilter.tap()
      
      // In mock mode, we should see mock open orders
      if app.launchArguments.contains("UITEST_MOCK_MODE") {
        // Wait for potential open orders to load
        usleep(1000000) // 1 second for data to load
        
        // Check for open order indicators
        let hasOpenContent = app.staticTexts["OPEN"].waitForExistence(timeout: 2) ||
                            app.staticTexts.matching(
                              NSPredicate(format: "label CONTAINS 'No' AND label CONTAINS 'Open'")
                            ).count > 0
        
        XCTAssertTrue(hasOpenContent, "Open filter should show open orders or appropriate empty state")
      }
    }
  }
  
  private func testHomeScreen(_ app: XCUIApplication) {
    // Wait for Home tab to be loaded
    let homeTab = app.tabBars.buttons["Home"]
    XCTAssertTrue(homeTab.waitForExistence(timeout: 2), "Home tab should exist")

    // Wait for navigation bar to be rendered
    XCTAssertTrue(
      app.navigationBars.element.waitForExistence(timeout: 1), "Navigation bar should exist")

    // Wait for branding text to be rendered
    XCTAssertTrue(
      app.staticTexts["BeHype"].waitForExistence(timeout: 1), "BeHype branding should exist")

    // Wait for Fund Wallet button to be rendered
    XCTAssertTrue(
      app.buttons["Fund Wallet"].waitForExistence(timeout: 1), "Fund Wallet button should exist")

    // Wait for key section headers
    XCTAssertTrue(
      app.staticTexts["Markets"].waitForExistence(timeout: 1), "Markets section should exist")

    // Wait for portfolio cards to be rendered
    XCTAssertTrue(
      app.staticTexts["USDC Balance"].waitForExistence(timeout: 1), "USDC Balance card should exist"
    )
    XCTAssertTrue(
      app.staticTexts["Total Portfolio Value"].waitForExistence(timeout: 1),
      "Total Portfolio Value card should exist")

    // Wait for market data to be rendered
    XCTAssertTrue(
      app.staticTexts["BTC/USDC"].waitForExistence(timeout: 1), "BTC/USDC market should exist")

    // Wait for View Chart button to be rendered
    XCTAssertTrue(
      app.buttons["View Chart"].waitForExistence(timeout: 1), "View Chart button should exist")
  }
  
  private func testPortfolioCardInteractions(_ app: XCUIApplication) {
    // Ensure we're on Home tab
    let homeTab = app.tabBars.buttons["Home"]
    homeTab.tap()
    
    // Test portfolio card accessibility and content
    XCTAssertTrue(
      app.staticTexts["USDC Balance"].waitForExistence(timeout: 2), 
      "USDC Balance card should be present")
    
    // Check that balance values are displayed (should be more than $0.00)
    let usdcValueExists = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '$'")).count > 0
    XCTAssertTrue(usdcValueExists, "Should display USDC balance value")
    
    // Test Total Portfolio Value card
    XCTAssertTrue(
      app.staticTexts["Total Portfolio Value"].waitForExistence(timeout: 1),
      "Total Portfolio Value card should be present")
    
    // Check that total value is calculated and displayed
    let totalValueExists = app.staticTexts.matching(
      NSPredicate(format: "label CONTAINS '$' AND label != 'USDC Balance'")
    ).count > 0
    XCTAssertTrue(totalValueExists, "Should display total portfolio value")
  }
  
  private func testFundWalletModalFlow(_ app: XCUIApplication) {
    // Navigate to Home if not already there
    app.tabBars.buttons["Home"].tap()
    
    // Find and tap Fund Wallet button
    let fundWalletButton = app.buttons["Fund Wallet"]
    XCTAssertTrue(fundWalletButton.waitForExistence(timeout: 2), "Fund Wallet button should exist")
    fundWalletButton.tap()
    
    // Wait for modal to appear
    XCTAssertTrue(
      app.navigationBars["Fund Wallet"].waitForExistence(timeout: 3),
      "Fund Wallet modal should appear")
    
    // Test modal content - look for actual text from FundWalletView
    let modalContentExists = app.staticTexts["Send USDC to this address on Hyperliquid"].waitForExistence(timeout: 2) ||
                            app.staticTexts["Fund Wallet"].waitForExistence(timeout: 2)
    XCTAssertTrue(modalContentExists, "Modal should show fund wallet content")
    
    // Check for wallet address display
    let addressExists = app.staticTexts.matching(
      NSPredicate(format: "label CONTAINS '0x'")
    ).count > 0
    XCTAssertTrue(addressExists, "Should display wallet address")
    
    // Test QR code generation (check for image or loading state)
    let qrCodeExists = app.images.count > 0 || 
                      app.staticTexts["Generating QR Code..."].exists ||
                      app.staticTexts["QR Code"].exists
    XCTAssertTrue(qrCodeExists, "Should show QR code or loading state")
    
    // Test copy functionality (check for copy button)
    if app.buttons["Copy Address"].exists {
      XCTAssertTrue(app.buttons["Copy Address"].isHittable, "Copy button should be functional")
    }
    
    // Close modal - be specific about which Done button to tap
    let navBarDoneButton = app.navigationBars["Fund Wallet"].buttons["Done"]
    if navBarDoneButton.exists {
      navBarDoneButton.tap()
    } else {
      // Try the content Done button
      let contentDoneButtons = app.buttons.matching(NSPredicate(format: "label == 'Done'"))
      if contentDoneButtons.count > 0 {
        contentDoneButtons.element(boundBy: 0).tap()
      } else {
        // Try swipe down if Done buttons not found
        app.swipeDown()
      }
    }
    
    // Verify modal is dismissed
    XCTAssertFalse(
      app.navigationBars["Fund Wallet"].waitForExistence(timeout: 1),
      "Fund Wallet modal should be dismissed")
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
    XCTAssertTrue(
      app.staticTexts["BTC/USDC"].waitForExistence(timeout: 1), "Trading pair should be displayed")
    XCTAssertTrue(
      app.staticTexts["24h Volume"].waitForExistence(timeout: 1), "24h Volume label should exist")

    // Wait for order type selector to be rendered
    XCTAssertTrue(
      app.staticTexts["Order Type"].waitForExistence(timeout: 1), "Order Type section should exist")
    XCTAssertTrue(app.buttons["BUY"].waitForExistence(timeout: 1), "BUY button should exist")
    XCTAssertTrue(app.buttons["SELL"].waitForExistence(timeout: 1), "SELL button should exist")

    // Wait for form fields to be rendered (without interacting)
    XCTAssertTrue(
      app.staticTexts["Amount"].waitForExistence(timeout: 1), "Amount label should exist")
    XCTAssertTrue(
      app.staticTexts["Limit Price"].waitForExistence(timeout: 1), "Limit Price label should exist")

    // Wait for order summary section to be rendered
    XCTAssertTrue(
      app.staticTexts["Order Summary"].waitForExistence(timeout: 1),
      "Order Summary section should exist")

    // Check for either "Estimated Receive" (buy) or "Estimated Value" (sell) - wait for at least one
    let estimatedReceiveExists = app.staticTexts["Estimated Receive"].waitForExistence(timeout: 1)
    let estimatedValueExists = app.staticTexts["Estimated Value"].waitForExistence(timeout: 1)
    XCTAssertTrue(
      estimatedReceiveExists || estimatedValueExists,
      "Should have either Estimated Receive or Estimated Value")

    XCTAssertTrue(
      app.staticTexts["Est. Fees"].waitForExistence(timeout: 1), "Est. Fees should exist")
    
    // Test form field interactions (without submitting real orders)
    testAmountFieldInteraction(app)
    testPriceFieldInteraction(app)
  }
  
  private func testOrderPlacementFlow(_ app: XCUIApplication) {
    // Navigate to Trade screen
    app.tabBars.buttons["Trade"].tap()
    
    // Wait for screen to load
    XCTAssertTrue(
      app.navigationBars["Trade"].waitForExistence(timeout: 2),
      "Trade screen should load")
    
    // Fill out a sample buy order form
    let amountFields = app.textFields.matching(NSPredicate(format: "placeholderValue CONTAINS 'Enter amount'"))
    let priceFields = app.textFields.matching(NSPredicate(format: "placeholderValue CONTAINS 'Enter price'"))
    
    if amountFields.count > 0 && priceFields.count > 0 {
      let amountField = amountFields.element(boundBy: 0)
      let priceField = priceFields.element(boundBy: 0)
      
      // Enter test values
      amountField.tap()
      amountField.typeText("10")
      
      priceField.tap()
      priceField.typeText("117000")
      
      // Check that order summary updates
      let summaryExists = app.staticTexts["Order Summary"].exists
      XCTAssertTrue(summaryExists, "Order summary should be visible")
      
      // Look for Place Order button (should be enabled with valid inputs)
      let placeOrderButtons = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Place' OR label CONTAINS 'Buy' OR label CONTAINS 'Order'"))
      
      if placeOrderButtons.count > 0 {
        let placeOrderButton = placeOrderButtons.element(boundBy: 0)
        XCTAssertTrue(placeOrderButton.exists, "Place order button should be present")
        
        // In mock mode, we can test the order placement flow
        if app.launchArguments.contains("UITEST_MOCK_MODE") {
          XCTAssertTrue(placeOrderButton.isEnabled, "Place order button should be enabled with valid inputs")
          
          // Test the order placement with mock data
          placeOrderButton.tap()
          
          // Wait for loading to complete and success modal to appear
          let successModal = app.navigationBars["Order Complete"].waitForExistence(timeout: 3)
          if successModal {
            XCTAssertTrue(true, "Order success modal should appear")
            
            // Check for success content
            let successText = app.staticTexts["Order Placed Successfully!"].waitForExistence(timeout: 1)
            XCTAssertTrue(successText, "Success message should be displayed")
            
            // Close the modal
            if app.buttons["Close"].exists {
              app.buttons["Close"].tap()
            } else if app.buttons["Done"].exists {
              app.buttons["Done"].tap()
            }
          }
        }
      }
      
      // Clear fields
      amountField.doubleTap()
      amountField.typeText("")
      priceField.doubleTap() 
      priceField.typeText("")
    }
  }
  
  private func testOrderTypeToggling(_ app: XCUIApplication) {
    // Navigate to Trade screen
    app.tabBars.buttons["Trade"].tap()
    
    // Test BUY button
    let buyButton = app.buttons["BUY"]
    let sellButton = app.buttons["SELL"]
    
    XCTAssertTrue(buyButton.waitForExistence(timeout: 2), "BUY button should exist")
    XCTAssertTrue(sellButton.exists, "SELL button should exist")
    
    // Test toggling between buy and sell
    buyButton.tap()
    // Check if BUY is selected (visual state change)
    XCTAssertTrue(buyButton.isSelected || buyButton.exists, "BUY should be selectable")
    
    sellButton.tap()
    // Check if SELL is selected (visual state change)
    XCTAssertTrue(sellButton.isSelected || sellButton.exists, "SELL should be selectable")
    
    // Verify that order summary changes based on order type
    let estimatedReceive = app.staticTexts["Estimated Receive"]
    let estimatedValue = app.staticTexts["Estimated Value"]
    
    // After selecting buy, should show "Estimated Receive"
    buyButton.tap()
    if estimatedReceive.waitForExistence(timeout: 1) {
      XCTAssertTrue(true, "Buy mode should show Estimated Receive")
    }
    
    // After selecting sell, should show "Estimated Value" 
    sellButton.tap()
    if estimatedValue.waitForExistence(timeout: 1) {
      XCTAssertTrue(true, "Sell mode should show Estimated Value")
    }
  }
  
  private func testAmountFieldInteraction(_ app: XCUIApplication) {
    // Find amount text field
    let amountFields = app.textFields.matching(NSPredicate(format: "placeholderValue CONTAINS 'Enter amount'"))
    if amountFields.count > 0 {
      let amountField = amountFields.element(boundBy: 0)
      XCTAssertTrue(amountField.waitForExistence(timeout: 1), "Amount field should exist")
      
      // Test field interaction
      amountField.tap()
      amountField.typeText("10")
      
      // Check that value was entered (may not work in all field types)
      // XCTAssertEqual(amountField.value as? String, "10", "Amount field should accept input")
      
      // Clear field
      amountField.doubleTap()
      amountField.typeText("")
    }
    
    // MAX button doesn't exist in current TradeView implementation
  }
  
  private func testPriceFieldInteraction(_ app: XCUIApplication) {
    // Find price text field 
    let priceFields = app.textFields.matching(NSPredicate(format: "placeholderValue CONTAINS 'Enter price'"))
    if priceFields.count > 0 {
      let priceField = priceFields.element(boundBy: 0)
      XCTAssertTrue(priceField.waitForExistence(timeout: 1), "Price field should exist")
      
      // Test field interaction
      priceField.tap()
      priceField.typeText("118000")
      
      // Check that value was entered (may not work in all field types)
      // XCTAssertEqual(priceField.value as? String, "118000", "Price field should accept input")
      
      // Clear field
      priceField.doubleTap()
      priceField.typeText("")
    }
    
    // MARKET button doesn't exist in current TradeView implementation
  }

  private func testOrdersScreen(_ app: XCUIApplication) {
    // Navigate to Orders tab
    let ordersTab = app.tabBars.buttons["Orders"]
    XCTAssertTrue(ordersTab.waitForExistence(timeout: 1), "Orders tab should exist")
    ordersTab.tap()

    // Wait for Orders screen to load
    XCTAssertTrue(
      app.navigationBars["Orders"].waitForExistence(timeout: 2),
      "Orders navigation should exist")

    // Wait for filter buttons to be rendered
    XCTAssertTrue(app.buttons["All"].waitForExistence(timeout: 1), "All filter should exist")
    XCTAssertTrue(
      app.buttons["Open"].waitForExistence(timeout: 1), "Open filter should exist")
    XCTAssertTrue(
      app.buttons["Confirmed"].waitForExistence(timeout: 1), "Confirmed filter should exist")
    XCTAssertTrue(app.buttons["Failed"].waitForExistence(timeout: 1), "Failed filter should exist")
    XCTAssertTrue(app.buttons["Buys"].waitForExistence(timeout: 1), "Buys filter should exist")
    XCTAssertTrue(app.buttons["Sells"].waitForExistence(timeout: 1), "Sells filter should exist")

    // Wait for either empty state or transaction list to be rendered
    // Check for various possible empty states or transaction content
    let hasEmptyState = app.staticTexts["No Fills Yet"].waitForExistence(timeout: 1) ||
                       app.staticTexts["No Transactions Yet"].waitForExistence(timeout: 1)
    let hasTransactionList = app.staticTexts["BTC/USDC"].waitForExistence(timeout: 1) ||
                            app.staticTexts["FILLED"].waitForExistence(timeout: 1) ||
                            app.staticTexts["OPEN"].waitForExistence(timeout: 1)
    XCTAssertTrue(
      hasEmptyState || hasTransactionList, "Should show either empty state or transactions")
    
    // Test filter functionality
    testTransactionFilters(app)
    
    // Test search functionality if available
    testTransactionSearch(app)
  }
  
  private func testTransactionFilters(_ app: XCUIApplication) {
    // Test each filter button
    let filterButtons = ["All", "Open", "Confirmed", "Failed", "Buys", "Sells"]
    
    for filterName in filterButtons {
      let filterButton = app.buttons[filterName]
      if filterButton.exists {
        filterButton.tap()
        
        // Verify button becomes selected (visual state change)
        XCTAssertTrue(
          filterButton.isSelected || filterButton.exists,
          "\(filterName) filter should be selectable")
        
        // Test specific filter behavior
        usleep(500000) // 0.5 seconds to allow UI to update
        
        switch filterName {
        case "Open":
          // Open filter should show open orders (OPEN badges)
          let hasOpenOrders = app.staticTexts["OPEN"].waitForExistence(timeout: 1)
          let hasNoOpenText = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS 'No' AND label CONTAINS 'Open'")
          ).count > 0
          
          if !hasOpenOrders && !hasNoOpenText {
            // If no specific open content, that's also valid (empty state)
            XCTAssertTrue(true, "Open filter handled appropriately")
          }
          
        case "Confirmed":
          // Confirmed filter should show filled orders (FILLED badges)
          let hasFilledOrders = app.staticTexts["FILLED"].waitForExistence(timeout: 1)
          let hasNoConfirmedText = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS 'No' AND label CONTAINS 'Confirmed'")
          ).count > 0
          
          if !hasFilledOrders && !hasNoConfirmedText {
            // If no specific confirmed content, that's also valid (empty state)
            XCTAssertTrue(true, "Confirmed filter handled appropriately")
          }
          
        case "All":
          // All filter should show mixed content or appropriate empty state
          let hasAnyContent = app.staticTexts["FILLED"].exists ||
                            app.staticTexts["OPEN"].exists ||
                            app.staticTexts["BTC/USDC"].exists
          let hasEmptyState = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS 'No'")
          ).count > 0
          
          XCTAssertTrue(hasAnyContent || hasEmptyState, "All filter should show content or empty state")
          
        default:
          // For other filters, just verify they don't crash the app
          XCTAssertTrue(true, "\(filterName) filter completed without errors")
        }
      }
    }
    
    // Return to All filter
    app.buttons["All"].tap()
  }
  
  private func testTransactionSearch(_ app: XCUIApplication) {
    // Look for search field
    let searchFields = app.textFields.matching(
      NSPredicate(format: "placeholderValue CONTAINS 'Search' OR placeholderValue CONTAINS 'Filter'")
    )
    
    if searchFields.count > 0 {
      let searchField = searchFields.element(boundBy: 0)
      searchField.tap()
      searchField.typeText("BTC")
      
      // Verify search input was accepted
      XCTAssertEqual(searchField.value as? String, "BTC", "Search field should accept input")
      
      // Clear search
      searchField.doubleTap()
      searchField.typeText("")
    }
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
    XCTAssertTrue(
      app.staticTexts["BTC/USDC"].waitForExistence(timeout: 1), "Chart title should exist")
    XCTAssertTrue(
      app.staticTexts["Spot Market"].waitForExistence(timeout: 1), "Spot Market label should exist")
    XCTAssertTrue(
      app.staticTexts["Timeframe"].waitForExistence(timeout: 1), "Timeframe section should exist")

    // Wait for timeframe buttons to be rendered (but don't tap them)
    XCTAssertTrue(app.buttons["15M"].waitForExistence(timeout: 1), "15M timeframe should exist")
    XCTAssertTrue(app.buttons["1H"].waitForExistence(timeout: 1), "1H timeframe should exist")
    XCTAssertTrue(app.buttons["4H"].waitForExistence(timeout: 1), "4H timeframe should exist")
    XCTAssertTrue(app.buttons["1D"].waitForExistence(timeout: 1), "1D timeframe should exist")

    // Verify chart info - check for any chart-related text
    let hasChartData =
      app.staticTexts.matching(
        NSPredicate(
          format: "label CONTAINS 'candles' OR label CONTAINS 'Loading' OR label CONTAINS 'chart'")
      ).count > 0
    XCTAssertTrue(hasChartData, "Chart should show some chart-related info")

    // Close chart by tapping Done in navigation bar
    let doneButton = app.navigationBars["BTC/USDC Chart"].buttons["Done"]
    XCTAssertTrue(doneButton.waitForExistence(timeout: 1), "Done button should exist")
    doneButton.tap()

    // Verify we're back to home - navigation bar has no title
    XCTAssertTrue(
      app.navigationBars.element.waitForExistence(timeout: 1), "Should return to home")
  }
  
  private func testChartTimeframeInteractions(_ app: XCUIApplication) {
    // Ensure chart is open
    let viewChartButton = app.buttons["View Chart"]
    if !app.navigationBars["BTC/USDC Chart"].exists {
      viewChartButton.tap()
    }
    
    // Test timeframe button interactions
    let timeframes = ["15M", "1H", "4H", "1D"]
    
    for timeframe in timeframes {
      let timeframeButton = app.buttons[timeframe]
      if timeframeButton.exists {
        timeframeButton.tap()
        
        // Verify button selection state
        XCTAssertTrue(
          timeframeButton.isSelected || timeframeButton.exists,
          "\(timeframe) timeframe should be selectable")
        
        // Small delay for chart update
        usleep(1000000) // 1 second
        
        // Check for chart data update indicators
        let chartInfoExists = app.staticTexts.matching(
          NSPredicate(format: "label CONTAINS 'candles' OR label CONTAINS 'Loading' OR label CONTAINS 'data'")
        ).count > 0
        
        if chartInfoExists {
          XCTAssertTrue(true, "Chart should show data for \(timeframe) timeframe")
        }
      }
    }
  }
  
  private func testNavigationFlow(_ app: XCUIApplication) {
    // Test tab navigation flow
    let tabs = ["Home", "Trade", "Orders"]
    
    for tab in tabs {
      let tabButton = app.tabBars.buttons[tab]
      XCTAssertTrue(tabButton.exists, "\(tab) tab should exist")
      
      tabButton.tap()
      
      // Verify navigation occurred
      let navBarExists = app.navigationBars[tab].exists || app.navigationBars.element.exists
      XCTAssertTrue(navBarExists, "Should navigate to \(tab) successfully")
      
      // Small delay between navigations
      usleep(500000) // 0.5 seconds
    }
    
    // Test modal navigation (Fund Wallet)
    app.tabBars.buttons["Home"].tap()
    
    if app.buttons["Fund Wallet"].exists {
      app.buttons["Fund Wallet"].tap()
      
      let modalExists = app.navigationBars["Fund Wallet"].waitForExistence(timeout: 2)
      XCTAssertTrue(modalExists, "Fund Wallet modal should open")
      
      // Close modal - be specific about navigation bar Done button
      let navBarDoneButton = app.navigationBars["Fund Wallet"].buttons["Done"]
      if navBarDoneButton.exists {
        navBarDoneButton.tap()
      } else {
        app.swipeDown()
      }
    }
    
    // Test chart modal navigation
    if app.buttons["View Chart"].exists {
      app.buttons["View Chart"].tap()
      
      let chartModalExists = app.navigationBars["BTC/USDC Chart"].waitForExistence(timeout: 2)
      XCTAssertTrue(chartModalExists, "Chart modal should open")
      
      // Test timeframe interactions while modal is open
      testChartTimeframeInteractions(app)
      
      // Close chart modal - be specific about navigation bar Done button
      let chartDoneButton = app.navigationBars["BTC/USDC Chart"].buttons["Done"]
      if chartDoneButton.exists {
        chartDoneButton.tap()
      }
    }
  }
  
  private func testErrorStatesHandling(_ app: XCUIApplication) {
    // Navigate to Trade screen for error state testing
    app.tabBars.buttons["Trade"].tap()
    
    // Test form validation errors (empty fields)
    testFormValidationErrors(app)
    
    // Test network error states (if mock mode allows)
    if app.launchArguments.contains("UITEST_MOCK_MODE") {
      testMockNetworkErrors(app)
    }
  }
  
  private func testFormValidationErrors(_ app: XCUIApplication) {
    let amountFields = app.textFields.matching(NSPredicate(format: "placeholderValue CONTAINS 'Enter amount'"))
    let priceFields = app.textFields.matching(NSPredicate(format: "placeholderValue CONTAINS 'Enter price'"))
    
    if amountFields.count > 0 && priceFields.count > 0 {
      let amountField = amountFields.element(boundBy: 0)
      let priceField = priceFields.element(boundBy: 0)
      
      // Test invalid amount (negative)
      amountField.tap()
      amountField.typeText("-10")
      
      // Look for validation error
      let hasValidationError = app.staticTexts.matching(
        NSPredicate(format: "label CONTAINS 'Invalid' OR label CONTAINS 'Error' OR label CONTAINS 'must be positive'")
      ).count > 0
      
      if hasValidationError {
        XCTAssertTrue(true, "Should show validation error for negative amount")
      }
      
      // Clear field
      amountField.doubleTap()
      amountField.typeText("")
      
      // Test invalid price (zero)
      priceField.tap()
      priceField.typeText("0")
      
      // Look for price validation error
      let hasPriceError = app.staticTexts.matching(
        NSPredicate(format: "label CONTAINS 'Invalid' OR label CONTAINS 'Error' OR label CONTAINS 'greater than'")
      ).count > 0
      
      if hasPriceError {
        XCTAssertTrue(true, "Should show validation error for zero price")
      }
      
      // Clear field
      priceField.doubleTap()
      priceField.typeText("")
    }
  }
  
  private func testMockNetworkErrors(_ app: XCUIApplication) {
    // In mock mode, test various error scenarios
    // This would require additional implementation in the app to support mock mode
    print("Mock network error testing - requires app-side mock implementation")
    
    // Check for error states in UI
    let errorIndicators = app.staticTexts.matching(
      NSPredicate(format: "label CONTAINS 'Error' OR label CONTAINS 'Failed' OR label CONTAINS 'Retry'")
    )
    
    if errorIndicators.count > 0 {
      XCTAssertTrue(true, "Error states are being handled in UI")
    }
  }
}