#!/usr/bin/env swift

import Foundation

print("🧪 Swift getAllMids Test Script (Synchronous)")
print("=" + String(repeating: "=", count: 49))

// Test the Hyperliquid API using synchronous URLSession
func testHyperliquidAPISync() {
    print("📡 Testing Hyperliquid API directly...")
    
    guard let url = URL(string: "https://api.hyperliquid.xyz/info") else {
        print("❌ Invalid URL")
        return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.timeoutInterval = 10.0
    
    // Same request body as getAllMids uses
    let requestBody = [
        "type": "allMids"
    ]
    
    do {
        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
        request.httpBody = jsonData
        
        print("📤 Making API request to Hyperliquid...")
        
        let semaphore = DispatchSemaphore(value: 0)
        var responseData: Data?
        var responseError: Error?
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            responseData = data
            responseError = error
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📥 Response status: \(httpResponse.statusCode)")
            }
            
            semaphore.signal()
        }
        
        task.resume()
        
        // Wait for response with timeout
        let timeout = semaphore.wait(timeout: .now() + 15.0)
        
        if timeout == .timedOut {
            print("⏰ Request timed out")
            return
        }
        
        if let error = responseError {
            print("❌ Network error: \(error)")
            return
        }
        
        guard let data = responseData else {
            print("❌ No data received")
            return
        }
        
        // Parse the JSON response
        guard let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("❌ Failed to parse JSON response")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Raw response: \(responseString.prefix(500))")
            }
            return
        }
        
        print("📊 Received response with \(jsonObject.count) markets")
        
        // Check for BTC variants FIRST
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
            print("\n🟢 SUCCESS: BTC variants ARE available in the API response!")
        } else {
            print("\n🔴 PROBLEM: BTC variants are NOT in the API response")
        }
        
        print("\n📈 Total markets in response: \(jsonObject.count)")
        
        // Show first 20 markets alphabetically
        let sortedMarkets = jsonObject.sorted { $0.key < $1.key }
        print("\n🔍 First 20 markets (alphabetically sorted):")
        for (index, (market, price)) in sortedMarkets.prefix(20).enumerated() {
            print("  \(index + 1): \(market) = \(price)")
        }
        
        // Show what a random selection of 10 would look like
        print("\n🎲 Random sample of 10 markets (simulating getAllMids limit):")
        let randomMarkets = Array(jsonObject.shuffled().prefix(10))
        for (index, (market, price)) in randomMarkets.enumerated() {
            print("  \(index + 1): \(market) = \(price)")
        }
        
        // Check if BTC would be in random samples
        print("\n🧪 Testing random sampling (like getAllMids might do):")
        var btcFoundInSamples = 0
        let testRuns = 5
        
        for run in 1...testRuns {
            let sample = Array(jsonObject.shuffled().prefix(10))
            let sampleKeys = Set(sample.map { $0.key })
            let btcInSample = btcVariants.first { sampleKeys.contains($0) } != nil
            
            print("  Run \(run): BTC in random 10? \(btcInSample ? "✅ YES" : "❌ NO")")
            if btcInSample { btcFoundInSamples += 1 }
        }
        
        print("\n📊 BTC found in \(btcFoundInSamples)/\(testRuns) random samples")
        print("💡 This explains why iOS getAllMids sometimes misses BTC!")
        
    } catch {
        print("❌ Error: \(error)")
    }
}

// Run the test
testHyperliquidAPISync()
print("\n✨ Test complete!")