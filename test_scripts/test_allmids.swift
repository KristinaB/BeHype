#!/usr/bin/env swift

import Foundation

// Import the framework
import Cocoa

// We need to use the same imports as the iOS framework
// Let's create a simple version that mimics the structure

print("🧪 Swift getAllMids Test Script")
print("=" + String(repeating: "=", count: 49))

// Simple HTTP request to test the same API endpoint that getAllMids uses
func testHyperliquidAPI() async {
    print("📡 Testing Hyperliquid API directly...")
    
    // Create the same request that getAllMids makes
    guard let url = URL(string: "https://api.hyperliquid.xyz/info") else {
        print("❌ Invalid URL")
        return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    // Same request body as getAllMids
    let requestBody = [
        "type": "allMids"
    ]
    
    do {
        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
        request.httpBody = jsonData
        
        print("📤 Making API request...")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("📥 Response status: \(httpResponse.statusCode)")
        }
        
        // Parse the JSON response
        if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
            print("📊 Received response with \(jsonObject.count) markets")
            
            // Sort by market name to see consistent ordering
            let sortedMarkets = jsonObject.sorted { $0.key < $1.key }
            
            print("\n🔍 First 20 markets (alphabetically sorted):")
            for (index, (market, price)) in sortedMarkets.prefix(20).enumerated() {
                print("  \(index + 1): \(market) = \(price)")
            }
            
            print("\n🎯 Looking for BTC variants:")
            let btcVariants = ["@142", "BTC", "UBTC", "BTC/USDC", "UBTC/USDC"]
            var foundBTC = false
            
            for variant in btcVariants {
                if let price = jsonObject[variant] {
                    print("✅ Found \(variant): $\(price)")
                    foundBTC = true
                } else {
                    print("❌ Missing \(variant)")
                }
            }
            
            if foundBTC {
                print("\n🟢 BTC variants ARE available in the API response")
            } else {
                print("\n🔴 BTC variants are NOT in the API response")
            }
            
            print("\n📈 Total markets in response: \(jsonObject.count)")
            
            // Show some random markets to understand the data structure
            print("\n🎲 Random sample of 10 markets:")
            let randomMarkets = Array(jsonObject.shuffled().prefix(10))
            for (index, (market, price)) in randomMarkets.enumerated() {
                print("  \(index + 1): \(market) = \(price)")
            }
            
        } else {
            print("❌ Failed to parse JSON response")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Raw response: \(responseString.prefix(500))")
            }
        }
        
    } catch {
        print("❌ Error: \(error)")
    }
}

// Run the test
Task {
    await testHyperliquidAPI()
    print("\n✨ Test complete!")
    exit(0)
}