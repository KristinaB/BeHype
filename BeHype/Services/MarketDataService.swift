//
//  MarketDataService.swift
//  BeHype
//
//  Service for managing market data, prices, and candle information
//

import Foundation
import SwiftUI

class MarketDataService: ObservableObject {
  @Published var btcPrice: String = "0.0"
  @Published var exchangeAssets: Int = 0
  @Published var isLoading: Bool = false
  @Published var status: String = ""

  private var client: HyperliquidClient?

  init() {
    let sdk = HyperliquidSwiftSDK()
    self.client = sdk.createClient()
  }

  func fetchExchangeData() {
    isLoading = true
    status = "Connecting to Hyperliquid..."

    DispatchQueue.global(qos: .background).async {
      guard let client = self.client else {
        DispatchQueue.main.async {
          self.status = "Client not initialized"
          self.isLoading = false
        }
        return
      }

      // Get exchange metadata using the framework
      let meta = client.getExchangeMeta()

      // Use direct API call for BTC price
      self.fetchBTCPrice()

      DispatchQueue.main.async {
        self.exchangeAssets = Int(meta.totalAssets)
        self.status = "✅ Connected! Exchange has \(meta.totalAssets) assets"
        self.isLoading = false
      }
    }
  }

  private func fetchBTCPrice() {
    print("🔧 [MarketDataService] Fetching BTC price for @142...")

    guard let url = URL(string: "https://api.hyperliquid.xyz/info") else {
      print("❌ [MarketDataService] Invalid API URL")
      return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.timeoutInterval = 10.0

    let requestBody = ["type": "allMids"]

    do {
      let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
      request.httpBody = jsonData

      let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
        if let error = error {
          print("❌ [MarketDataService] API request failed: \(error)")
          return
        }

        guard let data = data else {
          print("❌ [MarketDataService] No data received")
          return
        }

        do {
          guard let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any]
          else {
            print("❌ [MarketDataService] Failed to parse JSON")
            return
          }

          print("📊 [MarketDataService] API returned \(jsonObject.count) markets")

          DispatchQueue.main.async {
            if let priceValue = jsonObject["@142"] as? String,
              let price = Double(priceValue)
            {
              print("✅ [MarketDataService] Found @142 price: $\(price)")
              self?.btcPrice = String(format: "%.2f", price)
            } else {
              print("❌ [MarketDataService] @142 not found in API response")
              self?.btcPrice = "0.00"
            }
          }

        } catch {
          print("❌ [MarketDataService] JSON parsing error: \(error)")
        }
      }

      task.resume()

    } catch {
      print("❌ [MarketDataService] Request creation error: \(error)")
    }
  }

  func getCandles(interval: String, hoursBack: Int) -> [CandleData] {
    guard let client = client else {
      print("❌ [MarketDataService] Client not initialized")
      return []
    }

    let endTime = UInt64(Date().timeIntervalSince1970 * 1000)
    let startTime = endTime - UInt64(hoursBack * 60 * 60 * 1000)

    return client.getCandlesSnapshot(
      coin: "@142",  // BTC/USDC spot
      interval: interval,
      startTime: startTime,
      endTime: endTime
    )
  }

  func getCandleData() {
    print("📈 [MarketDataService] Starting getCandleData...")

    guard let client = client else {
      print("❌ [MarketDataService] Client not initialized")
      status = "❌ Client not initialized"
      return
    }

    isLoading = true
    status = "📈 Fetching BTC/USDC spot candle data..."

    DispatchQueue.global(qos: .background).async {
      // Get candles for the last 24 hours (using milliseconds for timestamps)
      let endTime = UInt64(Date().timeIntervalSince1970 * 1000)  // milliseconds
      let startTime = endTime - (24 * 60 * 60 * 1000)  // 24 hours ago in milliseconds

      let candles = client.getCandlesSnapshot(
        coin: "@142",  // Use @142 for BTC/USDC spot pair (index 142)
        interval: "1h",
        startTime: startTime,
        endTime: endTime
      )

      DispatchQueue.main.async {
        print("📈 [MarketDataService] Retrieved \(candles.count) candles")

        if !candles.isEmpty {
          let latestCandle = candles.last!
          self.status = "📈 Latest BTC price: $\(latestCandle.close) (from \(candles.count) candles)"

          // Log first few candles for debugging
          for (index, candle) in candles.prefix(3).enumerated() {
            print(
              "📊 [MarketDataService] Candle \(index): Open=\(candle.open), Close=\(candle.close), High=\(candle.high), Low=\(candle.low)"
            )
          }
        } else {
          self.status = "⚠️ No candle data found"
        }

        self.isLoading = false
      }
    }
  }
}
