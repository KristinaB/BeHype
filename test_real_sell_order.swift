#!/usr/bin/env swift

import Foundation

// Test real sell limit order with user's actual balance
// Balance: 0.0000899371 BTC (from user's debug output)

print("🚀 [TEST] Real Sell Limit Order with Actual Balance")
print("=" + String(repeating: "=", count: 55))

let actualBalance = "0.0000899371"
print("\n💰 Using your actual BTC balance: \(actualBalance)")

// Get current market price (from previous debug: $118144.5)
// Add small premium for limit sell order
let marketPrice = 118144.5
let sellPremium = 50.0  // Sell $50 above market for better execution
let targetPrice = marketPrice + sellPremium

print("📈 Current market price: $\(String(format: "%.1f", marketPrice))")
print("🎯 Target sell price: $\(String(format: "%.1f", targetPrice))")

// Apply our rounding logic (same as iOS app)
func roundPriceToTickSize(price: Double, tickSize: Double) -> String {
    let rounded = (price / tickSize).rounded() * tickSize
    return String(format: "%.1f", rounded)
}

func roundBtcAmount(amount: String) -> String {
    guard let amountDouble = Double(amount) else { return amount }
    let rounded = (amountDouble * 100000).rounded() / 100000 // Round to 5 decimal places
    return String(format: "%.5f", rounded)
}

let roundedPrice = roundPriceToTickSize(price: targetPrice, tickSize: 0.5)
let roundedAmount = roundBtcAmount(amount: actualBalance)

print("\n📏 After rounding for compliance:")
print("  • BTC amount: \(actualBalance) → \(roundedAmount)")
print("  • Sell price: $\(String(format: "%.1f", targetPrice)) → $\(roundedPrice)")

// Calculate expected USD proceeds
let expectedUSD = Double(roundedAmount)! * Double(roundedPrice)!
print("  • Expected proceeds: $\(String(format: "%.2f", expectedUSD))")

print("\n🔄 This would execute:")
print("  walletClient.placeBtcSellOrder(")
print("    btcAmount: \"\(roundedAmount)\",")
print("    limitPrice: \"\(roundedPrice)\"")
print("  )")

print("\n✅ Order parameters ready!")
print("💡 In the iOS app, tap SELL with:")
print("   • Amount: \(roundedAmount) BTC")
print("   • Price: $\(roundedPrice)")
print("   • This should now work without 'tick size' errors!")

print("\n🎯 Expected result:")
print("   ✅ Order placed successfully")
print("   📋 Receive order ID from Hyperliquid")
print("   💰 Get ~$\(String(format: "%.2f", expectedUSD)) when filled")
print("   📊 Balance updates automatically")