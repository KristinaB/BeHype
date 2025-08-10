#!/usr/bin/env swift

import Foundation

// Comprehensive debug script for sell limit order functionality
// This script tests the Rust SDK limit order methods with extensive logging

print("🔧 [DEBUG] Sell Limit Order Debug Script")
print("=" + String(repeating: "=", count: 50))

// Simulate the exact parameters from your failing order
let btcAmount = "0.0000899371"
let limitPrice = "118163.50"

print("\n📊 [DEBUG] Testing sell limit order with:")
print("  • BTC Amount: \(btcAmount)")
print("  • Limit Price: $\(limitPrice)")
print("  • Asset: @142 (BTC/USDC spot)")

// Test parameter validation
print("\n🔍 [DEBUG] Parameter validation:")
if let btcAmountDouble = Double(btcAmount) {
    print("  ✅ BTC amount parses to double: \(btcAmountDouble)")
    if btcAmountDouble > 0 {
        print("  ✅ BTC amount is positive")
    } else {
        print("  ❌ BTC amount is not positive!")
    }
} else {
    print("  ❌ BTC amount cannot be parsed as double!")
}

if let limitPriceDouble = Double(limitPrice) {
    print("  ✅ Limit price parses to double: \(limitPriceDouble)")
    if limitPriceDouble > 0 {
        print("  ✅ Limit price is positive")
    } else {
        print("  ❌ Limit price is not positive!")
    }
} else {
    print("  ❌ Limit price cannot be parsed as double!")
}

// Simulate the Rust SDK call structure
print("\n🔄 [DEBUG] Simulating Rust SDK placeBtcSellOrder call...")
print("  • Method: walletClient.placeBtcSellOrder(btcAmount: \"\(btcAmount)\", limitPrice: \"\(limitPrice)\")")

// Test precision requirements
print("\n🎯 [DEBUG] Precision analysis:")
let btcAmountComponents = btcAmount.split(separator: ".")
if btcAmountComponents.count == 2 {
    let decimalPlaces = btcAmountComponents[1].count
    print("  • BTC amount decimal places: \(decimalPlaces)")
    if decimalPlaces <= 5 {
        print("  ✅ BTC precision within 5 decimal limit")
    } else {
        print("  ⚠️ BTC precision exceeds 5 decimal limit (might cause issues)")
    }
}

let limitPriceComponents = limitPrice.split(separator: ".")
if limitPriceComponents.count == 2 {
    let decimalPlaces = limitPriceComponents[1].count
    print("  • Limit price decimal places: \(decimalPlaces)")
    if decimalPlaces <= 2 {
        print("  ✅ Price precision within 2 decimal limit")
    } else {
        print("  ⚠️ Price precision exceeds 2 decimal limit (might cause issues)")
    }
}

// Test order size validation
print("\n💰 [DEBUG] Order size validation:")
if let btcAmountDouble = Double(btcAmount) {
    let usdValue = btcAmountDouble * Double(limitPrice)!
    print("  • Estimated USD value: $\(String(format: "%.2f", usdValue))")
    
    // Hyperliquid typically has minimum order sizes
    if usdValue >= 1.0 {
        print("  ✅ Order value meets typical minimum ($1+)")
    } else {
        print("  ⚠️ Order value below typical minimum ($1) - might be rejected")
    }
}

// Common failure scenarios
print("\n❌ [DEBUG] Common failure scenarios to check:")
print("  1. Insufficient BTC balance for sell order")
print("  2. Invalid asset symbol (@142 vs BTC)")
print("  3. Price too far from market price")
print("  4. Minimum order size not met")
print("  5. Wallet/private key issues")
print("  6. Network connectivity problems")
print("  7. API rate limiting")
print("  8. Invalid time-in-force parameter")

// Test different parameter formats
print("\n🧪 [DEBUG] Testing parameter format variations:")

// Test without extra precision
let simpleBtcAmount = String(format: "%.5f", Double(btcAmount)!)
let simpleLimitPrice = String(format: "%.2f", Double(limitPrice)!)
print("  • Simplified BTC amount: \(simpleBtcAmount)")
print("  • Simplified limit price: \(simpleLimitPrice)")

// Test with different asset formats
print("  • Asset formats to try: @142, BTC, UBTC, BTC/USDC")

// Simulate error conditions
print("\n🚨 [DEBUG] Simulating potential error responses:")
print("  • Error 1: 'Insufficient balance' - Not enough BTC to sell")
print("  • Error 2: 'Invalid size' - Order size below minimum")
print("  • Error 3: 'Price out of range' - Limit price too far from market")
print("  • Error 4: 'Asset not found' - Invalid asset symbol")
print("  • Error 5: 'Order rejected' - General order rejection")

// Recommend debugging steps
print("\n🔧 [DEBUG] Recommended debugging steps:")
print("  1. Check current BTC balance before sell order")
print("  2. Verify current market price vs limit price")
print("  3. Test with smaller BTC amount first")
print("  4. Check Rust SDK error messages in detail")
print("  5. Verify wallet is properly loaded with private key")
print("  6. Test buy order to confirm wallet functionality")

// Mock successful vs failed response
print("\n📋 [DEBUG] Expected SwapResult structure:")
print("Success case:")
print("  SwapResult {")
print("    success: true,")
print("    message: 'Order placed successfully',")
print("    orderId: Some(12345678),")
print("    filledSize: Some('0.0000899371'),")
print("    avgPrice: Some('118163.50')")
print("  }")

print("\nFailure case (what we're getting):")
print("  SwapResult {")
print("    success: false,")
print("    message: '<ERROR_MESSAGE_HERE>',")
print("    orderId: None,")
print("    filledSize: None,")
print("    avgPrice: None")
print("  }")

print("\n🎯 [DEBUG] Next steps:")
print("  1. Run this script to understand the parameters")
print("  2. Check Rust SDK logs for detailed error message")
print("  3. Verify balance and wallet state")
print("  4. Test with known working parameters")
print("  5. Compare with successful $11 buy order flow")

print("\n✅ Debug script complete! Check the Rust SDK error message for specific failure reason.")