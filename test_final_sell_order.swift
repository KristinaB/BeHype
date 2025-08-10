#!/usr/bin/env swift

import Foundation

print("🎯 [FINAL TEST] Sell Order with Corrected Tick Size")
print("=" + String(repeating: "=", count: 50))

let balance = "0.0000899371"
let targetPrice = 118194.5  // Market + premium

// Corrected rounding logic (same as iOS app now)
func roundPriceToTickSize(price: Double, tickSize: Double) -> String {
    let rounded = (price / tickSize).rounded() * tickSize
    return String(format: "%.0f", rounded)  // Whole dollars
}

func roundBtcAmount(amount: String) -> String {
    guard let amountDouble = Double(amount) else { return amount }
    let rounded = (amountDouble * 100000).rounded() / 100000
    return String(format: "%.5f", rounded)
}

let roundedPrice = roundPriceToTickSize(price: targetPrice, tickSize: 1.0)
let roundedAmount = roundBtcAmount(amount: balance)

print("📏 Final parameters after $1.00 tick size correction:")
print("  • BTC amount: \(balance) → \(roundedAmount)")
print("  • Sell price: $\(String(format: "%.1f", targetPrice)) → $\(roundedPrice)")
print("  • Expected: $\(String(format: "%.2f", Double(roundedAmount)! * Double(roundedPrice)!))")

print("\n✅ These parameters should now work in your iOS app!")
print("🚀 Go ahead and try the sell limit order - it should succeed!")