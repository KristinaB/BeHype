//
//  MarketDataService.swift
//  BeHype
//
//  Service for managing market data, prices, and candle information
//

import Foundation
import SwiftUI

// MARK: - Asset Data Structure
struct AssetData: Identifiable, Hashable {
  let id: String // Asset key like "@142"
  let name: String // Display name like "BTC/USDC"
  let price: String // Current price
  
  init(id: String, name: String, price: String) {
    self.id = id
    self.name = name
    self.price = price
  }
}

class MarketDataService: ObservableObject {
  @Published var btcPrice: String = "0.0"
  @Published var exchangeAssets: Int = 0
  @Published var availableAssets: [AssetData] = []
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
    print("🔧 [MarketDataService] Fetching all asset prices...")

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
            // Update BTC price for backward compatibility
            if let priceValue = jsonObject["@142"] as? String,
              let price = Double(priceValue)
            {
              print("✅ [MarketDataService] Found @142 price: $\(price)")
              self?.btcPrice = String(format: "%.2f", price)
            } else {
              print("❌ [MarketDataService] @142 not found in API response")
              self?.btcPrice = "0.00"
            }
            
            // Populate availableAssets array
            var assets: [AssetData] = []
            
            // The allMids API returns mixed pricing:
            // @142 = BTC/USDC (actual USDC price)
            // Others = ratios to BTC or other bases
            // For now, let's calculate USDC prices by multiplying by BTC price
            
            let btcPriceInUsdc = jsonObject["@142"] as? String
            let btcPrice = Double(btcPriceInUsdc ?? "0") ?? 0
            
            var conversionLogCount = 0
            let maxConversionLogs = 3
            
            for (key, value) in jsonObject {
              if let priceString = value as? String,
                 let priceDouble = Double(priceString),
                 key.hasPrefix("@") {
                
                // Extract the numeric part after @
                let numericPart = key.dropFirst()
                if let assetIndex = Int(numericPart), assetIndex >= 142 {
                  let displayName = self?.getAssetDisplayName(for: key) ?? key
                  
                  // Filter out generic "Asset X" names
                  if !displayName.hasPrefix("Asset ") {
                    var finalPrice = priceDouble
                    
                    // Convert to USDC price if needed
                    if key == "@142" {
                      // BTC is already in USDC
                      finalPrice = priceDouble
                    } else if priceDouble >= 0.9 && priceDouble <= 1.1 {
                      // Likely stablecoins or 1:1 assets, keep as is
                      finalPrice = priceDouble
                    } else if priceDouble < 1 && priceDouble > 0.00001 {
                      // Likely a BTC ratio, convert to USDC
                      finalPrice = priceDouble * btcPrice
                      
                      // Only log first 3 conversions
                      if conversionLogCount < maxConversionLogs {
                        print("🔄 [MarketDataService] Converting \(key) (\(displayName)): \(priceDouble) * \(btcPrice) = \(finalPrice)")
                        conversionLogCount += 1
                      }
                    } else {
                      // For values > 1, assume they might already be in USDC or some other base
                      finalPrice = priceDouble
                    }
                    
                    // Use appropriate decimal places
                    let formattedPrice: String
                    if finalPrice >= 1000 {
                      formattedPrice = String(format: "%.2f", finalPrice)
                    } else if finalPrice >= 1 {
                      formattedPrice = String(format: "%.2f", finalPrice)
                    } else if finalPrice >= 0.01 {
                      formattedPrice = String(format: "%.4f", finalPrice)
                    } else {
                      formattedPrice = String(format: "%.6f", finalPrice)
                    }
                    
                    assets.append(AssetData(id: key, name: displayName, price: formattedPrice))
                  }
                }
              }
            }
            
            // Sort by asset ID for consistent ordering
            self?.availableAssets = assets.sorted { $0.id < $1.id }
            print("✅ [MarketDataService] Loaded \(assets.count) assets")
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
  
  private func getAssetDisplayName(for assetId: String) -> String {
    // Map known asset IDs to display names - focusing on spot pairs (USDC pairs)
    // Spot markets on Hyperliquid start at index @142
    let assetMappings: [String: String] = [
      // Spot markets (all are /USDC pairs)
      "@142": "BTC/USDC",
      "@143": "ETH/USDC", 
      "@144": "SOL/USDC",
      "@145": "ARB/USDC",
      "@146": "AVAX/USDC",
      "@147": "DOGE/USDC",
      "@148": "LTC/USDC",
      "@149": "BCH/USDC",
      "@150": "APT/USDC",
      "@151": "SUI/USDC",
      "@152": "OP/USDC",
      "@153": "INJ/USDC",
      "@154": "ORDI/USDC",
      "@155": "SEI/USDC",
      "@156": "BLUR/USDC",
      "@157": "LINK/USDC",
      "@158": "PEPE/USDC",
      "@159": "SHIB/USDC",
      "@160": "MATIC/USDC",
      "@161": "BNB/USDC",
      "@162": "TIA/USDC",
      "@163": "MANTA/USDC",
      "@164": "WIF/USDC",
      "@165": "JTO/USDC",
      "@166": "ATOM/USDC",
      "@167": "STX/USDC",
      "@168": "PYTH/USDC",
      "@169": "XRP/USDC",
      "@170": "FIL/USDC",
      "@171": "TAO/USDC",
      "@172": "WLD/USDC",
      "@173": "NEAR/USDC",
      "@174": "RNDR/USDC",
      "@175": "FTM/USDC",
      "@176": "TRX/USDC",
      "@177": "RUNE/USDC",
      "@178": "AAVE/USDC",
      "@179": "MKR/USDC",
      "@180": "MEME/USDC",
      "@181": "DYDX/USDC",
      "@182": "ICP/USDC",
      "@183": "IMX/USDC",
      "@184": "CRV/USDC",
      "@185": "TON/USDC",
      "@186": "APE/USDC",
      "@187": "ADA/USDC",
      "@188": "DOT/USDC",
      "@189": "LDO/USDC",
      "@190": "STG/USDC",
      "@191": "UNI/USDC",
      "@192": "SUSHI/USDC"
    ]
    
    if let mappedName = assetMappings[assetId] {
      return mappedName
    }
    
    // Fallback: just show the asset ID cleaned up
    // Since we're filtering for spot markets only, this shouldn't be reached often
    return assetId.replacingOccurrences(of: "@", with: "Asset ")
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
