import Foundation
import SwiftUI

// MARK: - Order Type Enum

enum OrderType: CaseIterable {
    case buy, sell
    
    var displayText: String {
        switch self {
        case .buy:
            return "Buy"
        case .sell:
            return "Sell"
        }
    }
}

// MARK: - Data Structures
// Note: Using SwapResult from the framework

class HyperliquidService: ObservableObject {
    @Published var status: String = "Ready"
    @Published var isLoading: Bool = false
    @Published var exchangeAssets: Int = 0
    @Published var usdcBalance: String = "0.0"
    @Published var btcBalance: String = "0.0"
    @Published var btcPrice: String = "0.0"
    @Published var lastSwapResult: String = ""
    @Published var userFills: [UserFill] = []
    
    private var sdk: HyperliquidSwiftSDK?
    private var client: HyperliquidClient?
    private var walletClient: HyperliquidClient?
    private var privateKey: String?
    private(set) var walletAddress: String = ""
    
    init() {
        setupSDK()
    }
    
    private func setupSDK() {
        self.sdk = HyperliquidSwiftSDK()
        self.client = sdk?.createClient()
        status = "SDK initialized"
    }
    
    func loadPrivateKey() {
        print("🔐 [DEBUG] Starting loadPrivateKey...")
        
        guard let keyPath = Bundle.main.path(forResource: "private-key", ofType: "key") else {
            print("❌ [DEBUG] Bundle.main.path returned nil for private-key.key")
            status = "Private key file not found in bundle"
            return
        }
        
        print("✅ [DEBUG] Found key path: \(keyPath)")
        
        guard let key = try? String(contentsOfFile: keyPath, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines) else {
            print("❌ [DEBUG] Failed to read file at path: \(keyPath)")
            status = "Failed to read private key file"
            return
        }
        
        print("✅ [DEBUG] Successfully read key file, length: \(key.count)")
        
        let cleanKey = key.hasPrefix("0x") ? String(key.dropFirst(2)) : key
        print("🔧 [DEBUG] Cleaned key length: \(cleanKey.count)")
        self.privateKey = cleanKey
        
        guard let sdk = sdk else {
            print("❌ [DEBUG] SDK is nil!")
            status = "SDK not initialized"
            return
        }
        
        print("🚀 [DEBUG] Creating wallet client...")
        self.walletClient = sdk.createClientWithWallet(privateKey: cleanKey)
        
        print("🏠 [DEBUG] Deriving address...")
        self.walletAddress = sdk.deriveAddress(from: cleanKey)
        
        print("✅ [DEBUG] Wallet setup complete. Address: \(walletAddress)")
        status = "Wallet loaded: \(String(walletAddress.prefix(10)))..."
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
            
            // Use direct API call for BTC price since getAllMids only returns random 10 markets
            self.fetchBTCPriceDirectly()
            
            DispatchQueue.main.async {
                self.exchangeAssets = Int(meta.totalAssets)
                
                print("💡 [DEBUG] Using direct API call for BTC price to work around getAllMids random sampling")
                
                self.status = "✅ Connected! Exchange has \(meta.totalAssets) assets"
                self.isLoading = false
            }
        }
    }
    
    func checkBalance() {
        print("💰 [DEBUG] Starting checkBalance...")
        print("💰 [DEBUG] walletClient: \(walletClient != nil ? "✅ Present" : "❌ Nil")")
        print("💰 [DEBUG] walletAddress: '\(walletAddress)' (isEmpty: \(walletAddress.isEmpty))")
        
        // If wallet not loaded, try loading it first
        if walletClient == nil || walletAddress.isEmpty {
            print("⚠️ [DEBUG] Wallet not loaded, attempting to load now...")
            loadPrivateKey()
            
            // Check again after loading
            print("🔄 [DEBUG] After loadPrivateKey:")
            print("    walletClient: \(walletClient != nil ? "✅ Present" : "❌ Nil")")
            print("    walletAddress: '\(walletAddress)' (isEmpty: \(walletAddress.isEmpty))")
        }
        
        guard let walletClient = walletClient, !walletAddress.isEmpty else {
            print("❌ [DEBUG] Guard failed - wallet not properly loaded even after attempt")
            status = "❌ Wallet not loaded - check console logs"
            return
        }
        
        print("✅ [DEBUG] Wallet client and address OK, proceeding...")
        isLoading = true
        status = "Checking balances..."
        
        DispatchQueue.global(qos: .background).async {
            let balances = walletClient.getTokenBalances(address: self.walletAddress)
            
            DispatchQueue.main.async {
                // Update USDC balance
                if let usdcBalance = balances.first(where: { $0.coin == "USDC" }) {
                    self.usdcBalance = usdcBalance.total
                } else {
                    self.usdcBalance = "0.0"
                }
                
                // Update BTC balance (UBTC is the spot BTC token on Hyperliquid)
                if let btcBalance = balances.first(where: { $0.coin == "BTC" || $0.coin == "UBTC" }) {
                    self.btcBalance = btcBalance.total
                } else {
                    self.btcBalance = "0.0"
                }
                
                self.status = "💵 USDC: \(self.usdcBalance) | ₿ BTC: \(self.btcBalance)"
                self.isLoading = false
            }
        }
    }
    
    func performSwap() {
        guard let walletClient = walletClient else {
            status = "❌ Wallet not loaded"
            return
        }
        
        let usdcAmount = Double(usdcBalance) ?? 0
        guard usdcAmount >= 11.0 else {
            status = "❌ Insufficient USDC balance (need at least $11)"
            return
        }
        
        isLoading = true
        status = "🔄 Swapping $11 USDC to BTC..."
        
        DispatchQueue.global(qos: .background).async {
            let result = walletClient.swapUsdcToBtc(usdcAmount: "11.0")
            
            DispatchQueue.main.async {
                if result.success {
                    var resultText = "✅ Swap successful!\n"
                    resultText += "Message: \(result.message)\n"
                    if let orderId = result.orderId {
                        resultText += "Order ID: \(orderId)\n"
                    }
                    if let filledSize = result.filledSize {
                        resultText += "Filled Size: \(filledSize)\n"
                    }
                    if let avgPrice = result.avgPrice {
                        resultText += "Avg Price: \(avgPrice)"
                    }
                    
                    self.status = "✅ Swap completed successfully"
                    self.lastSwapResult = resultText
                } else {
                    self.status = "❌ Swap failed: \(result.message)"
                    self.lastSwapResult = "❌ Failed: \(result.message)"
                }
                self.isLoading = false
            }
        }
    }
    
    func getCandles(interval: String, hoursBack: Int) -> [CandleData] {
        guard let client = client else {
            print("❌ [DEBUG] Client not initialized")
            return []
        }
        
        let endTime = UInt64(Date().timeIntervalSince1970 * 1000)
        let startTime = endTime - UInt64(hoursBack * 60 * 60 * 1000)
        
        return client.getCandlesSnapshot(
            coin: "@142", // BTC/USDC spot
            interval: interval,
            startTime: startTime,
            endTime: endTime
        )
    }
    
    func getCandleData() {
        print("📈 [DEBUG] Starting getCandleData...")
        
        guard let client = client else {
            print("❌ [DEBUG] Client not initialized")
            status = "❌ Client not initialized"
            return
        }
        
        isLoading = true
        status = "📈 Fetching BTC/USDC spot candle data..."
        
        DispatchQueue.global(qos: .background).async {
            // Get candles for the last 24 hours (using milliseconds for timestamps)
            let endTime = UInt64(Date().timeIntervalSince1970 * 1000) // milliseconds
            let startTime = endTime - (24 * 60 * 60 * 1000) // 24 hours ago in milliseconds
            
            let candles = client.getCandlesSnapshot(
                coin: "@142", // Use @142 for BTC/USDC spot pair (index 142)
                interval: "1h",
                startTime: startTime,
                endTime: endTime
            )
            
            DispatchQueue.main.async {
                print("📈 [DEBUG] Retrieved \(candles.count) candles")
                
                if !candles.isEmpty {
                    let latestCandle = candles.last!
                    self.status = "📈 Latest BTC price: $\(latestCandle.close) (from \(candles.count) candles)"
                    
                    // Log first few candles for debugging
                    for (index, candle) in candles.prefix(3).enumerated() {
                        print("📊 [DEBUG] Candle \(index): Open=\(candle.open), Close=\(candle.close), High=\(candle.high), Low=\(candle.low)")
                    }
                } else {
                    self.status = "⚠️ No candle data found"
                }
                
                self.isLoading = false
            }
        }
    }
    
    func runFullDemo() {
        print("🚀 [DEBUG] Starting runFullDemo...")
        loadPrivateKey()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            print("📊 [DEBUG] Running fetchExchangeData after 1s delay...")
            self.fetchExchangeData()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            print("💰 [DEBUG] Running checkBalance after 3s delay...")
            self.checkBalance()
        }
    }
    
    // MARK: - Direct API Methods
    
    private func fetchBTCPriceDirectly() {
        print("🔧 [DEBUG] Fetching BTC price directly from Hyperliquid API...")
        
        guard let url = URL(string: "https://api.hyperliquid.xyz/info") else {
            print("❌ [DEBUG] Invalid API URL")
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
                    print("❌ [DEBUG] API request failed: \(error)")
                    return
                }
                
                guard let data = data else {
                    print("❌ [DEBUG] No data received")
                    return
                }
                
                do {
                    guard let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                        print("❌ [DEBUG] Failed to parse JSON")
                        return
                    }
                    
                    print("📊 [DEBUG] Direct API returned \(jsonObject.count) markets")
                    
                    let btcVariants = ["@142", "BTC", "UBTC", "BTC/USDC", "UBTC/USDC"]
                    
                    DispatchQueue.main.async {
                        for variant in btcVariants {
                            if let priceValue = jsonObject[variant] as? String,
                               let price = Double(priceValue) {
                                print("✅ [DEBUG] Direct API found \(variant): $\(price)")
                                self?.btcPrice = String(format: "%.2f", price)
                                return
                            }
                        }
                        
                        print("❌ [DEBUG] No BTC variants found in direct API call")
                        self?.btcPrice = "0.00"
                    }
                    
                } catch {
                    print("❌ [DEBUG] JSON parsing error: \(error)")
                }
            }
            
            task.resume()
            
        } catch {
            print("❌ [DEBUG] Request creation error: \(error)")
        }
    }
    
    // MARK: - Limit Order Methods
    
    func placeLimitOrder(orderType: OrderType, amount: String, limitPrice: String, completion: @escaping (SwapResult) -> Void) {
        print("📋 [DEBUG] Placing \(orderType == .buy ? "BUY" : "SELL") limit order...")
        print("📋 [DEBUG] Amount: \(amount) \(orderType == .buy ? "USDC" : "BTC"), Price: $\(limitPrice)")
        
        guard let walletClient = walletClient else {
            completion(SwapResult(success: false, message: "❌ Wallet not loaded", orderId: nil, filledSize: nil, avgPrice: nil))
            return
        }
        
        // Temporary implementation: Use existing swapUsdcToBtc for $11 orders, simulate for others
        if orderType == .buy && amount == "11.0" {
            print("🔄 [DEBUG] Using existing swap method for $11 USDC order")
            isLoading = true
            status = "🔄 Placing buy order..."
            
            DispatchQueue.global(qos: .background).async {
                let result = walletClient.swapUsdcToBtc(usdcAmount: "11.0")
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if result.success {
                        var resultText = "✅ Buy order filled successfully!\n"
                        resultText += "Message: \(result.message)\n"
                        if let orderId = result.orderId {
                            resultText += "Order ID: \(orderId)\n"
                        }
                        if let filledSize = result.filledSize {
                            resultText += "Filled Size: \(filledSize)\n"
                        }
                        if let avgPrice = result.avgPrice {
                            resultText += "Avg Price: \(avgPrice)"
                        }
                        
                        self.status = "✅ Buy order filled"
                        self.lastSwapResult = resultText
                    } else {
                        self.status = "❌ Order failed: \(result.message)"
                        self.lastSwapResult = "❌ Failed: \(result.message)"
                    }
                    
                    completion(result)
                }
            }
        } else {
            // Use real limit order methods from rebuilt framework
            print("🔄 [DEBUG] Placing real limit order using Rust SDK...")
            
            isLoading = true
            status = "🔄 Placing \(orderType == .buy ? "buy" : "sell") limit order..."
            
            DispatchQueue.global(qos: .background).async {
                let result: SwapResult
                
                if orderType == .buy {
                    // For buy orders, amount is in USDC, convert BTC at limit price
                    result = walletClient.placeBtcBuyOrder(usdcAmount: amount, limitPrice: limitPrice)
                } else {
                    // For sell orders, amount is in BTC, sell at limit price
                    result = walletClient.placeBtcSellOrder(btcAmount: amount, limitPrice: limitPrice)
                }
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if result.success {
                        var resultText = "✅ \(orderType == .buy ? "Buy" : "Sell") order placed successfully!\n"
                        resultText += "Message: \(result.message)\n"
                        if let orderId = result.orderId {
                            resultText += "Order ID: \(orderId)\n"
                        }
                        if let filledSize = result.filledSize {
                            resultText += "Filled Size: \(filledSize)\n"
                        }
                        if let avgPrice = result.avgPrice {
                            resultText += "Average Price: $\(avgPrice)\n"
                        }
                        
                        self.status = resultText
                        self.lastSwapResult = resultText
                        
                        // Refresh balance after successful order
                        self.checkBalance()
                    } else {
                        self.status = "❌ Order failed: \(result.message)"
                        self.lastSwapResult = "❌ Failed: \(result.message)"
                    }
                    
                    completion(result)
                }
            }
        }
    }
    
    // Convenience methods for specific order types
    func placeBuyOrder(usdcAmount: String, limitPrice: String, completion: @escaping (SwapResult) -> Void) {
        placeLimitOrder(orderType: .buy, amount: usdcAmount, limitPrice: limitPrice, completion: completion)
    }
    
    func placeSellOrder(btcAmount: String, limitPrice: String, completion: @escaping (SwapResult) -> Void) {
        placeLimitOrder(orderType: .sell, amount: btcAmount, limitPrice: limitPrice, completion: completion)
    }
    
    // MARK: - Debug Methods
    
    func debugGetAllMids() {
        print("🧪 [DEBUG] Testing getAllMids method directly")
        print("=" + String(repeating: "=", count: 49))
        
        guard let client = client else {
            print("❌ [DEBUG] Client not initialized")
            return
        }
        
        // Test getAllMids multiple times to see if results change
        for attempt in 1...3 {
            print("\n📊 [DEBUG] getAllMids attempt #\(attempt):")
            let prices = client.getAllMids()
            
            print("📈 [DEBUG] Returned \(prices.count) entries:")
            for (index, price) in prices.enumerated() {
                print("  \(index + 1): \(price.coin) = \(price.price)")
            }
            
            // Check for BTC variants
            let btcVariants = ["@142", "BTC", "UBTC", "BTC/USDC", "UBTC/USDC"]
            var foundBTC = false
            print("\n🔍 [DEBUG] BTC variant check:")
            for variant in btcVariants {
                if let btcPrice = prices.first(where: { $0.coin == variant }) {
                    print("✅ [DEBUG] Found \(variant): $\(btcPrice.price)")
                    foundBTC = true
                } else {
                    print("❌ [DEBUG] Missing \(variant)")
                }
            }
            
            if !foundBTC {
                print("⚠️ [DEBUG] No BTC variants found in this batch")
            }
            
            // Small delay between attempts
            Thread.sleep(forTimeInterval: 0.5)
        }
        
        print("\n✨ [DEBUG] getAllMids test complete!")
    }
    
    func fetchUserFills(daysBack: Int = 30) {
        print("📋 [DEBUG] Starting fetchUserFills...")
        
        guard !walletAddress.isEmpty else {
            print("❌ [DEBUG] Wallet address is empty")
            status = "❌ Wallet not loaded"
            return
        }
        
        isLoading = true
        status = "📋 Fetching user fills..."
        
        DispatchQueue.global(qos: .background).async {
            let currentTime = UInt64(Date().timeIntervalSince1970 * 1000) // milliseconds
            let startTime = currentTime - UInt64(daysBack * 24 * 60 * 60 * 1000) // days ago
            
            let requestBody: [String: Any] = [
                "type": "userFillsByTime",
                "user": self.walletAddress,
                "startTime": startTime,
                "endTime": currentTime
            ]
            
            guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
                DispatchQueue.main.async {
                    self.status = "❌ Failed to create request"
                    self.isLoading = false
                }
                return
            }
            
            var request = URLRequest(url: URL(string: "https://api.hyperliquid.xyz/info")!)
            request.httpMethod = "POST"
            request.httpBody = jsonData
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if let error = error {
                        print("❌ [DEBUG] Network error: \(error)")
                        self.status = "❌ Network error"
                        return
                    }
                    
                    guard let data = data else {
                        print("❌ [DEBUG] No data received")
                        self.status = "❌ No data received"
                        return
                    }
                    
                    do {
                        if let fillsArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                            print("✅ [DEBUG] Received \(fillsArray.count) fills")
                            
                            let fills = fillsArray.compactMap { fillData -> UserFill? in
                                guard let coin = fillData["coin"] as? String,
                                      let px = fillData["px"] as? String,
                                      let sz = fillData["sz"] as? String,
                                      let side = fillData["side"] as? String,
                                      let time = fillData["time"] as? UInt64,
                                      let startPosition = fillData["startPosition"] as? String,
                                      let dir = fillData["dir"] as? String,
                                      let closedPnl = fillData["closedPnl"] as? String,
                                      let hash = fillData["hash"] as? String,
                                      let oid = fillData["oid"] as? UInt64,
                                      let crossed = fillData["crossed"] as? Bool else {
                                    print("⚠️ [DEBUG] Skipping malformed fill data")
                                    return nil
                                }
                                
                                let fee = fillData["fee"] as? String
                                let tid = fillData["tid"] as? UInt64
                                let feeToken = fillData["feeToken"] as? String
                                
                                return UserFill(
                                    coin: coin,
                                    px: px,
                                    sz: sz,
                                    side: side,
                                    time: time,
                                    startPosition: startPosition,
                                    dir: dir,
                                    closedPnl: closedPnl,
                                    hash: hash,
                                    oid: oid,
                                    crossed: crossed,
                                    fee: fee,
                                    tid: tid,
                                    feeToken: feeToken
                                )
                            }
                            
                            self.userFills = fills
                            self.status = "✅ Found \(fills.count) fills"
                            
                            // Log first fill for debugging
                            if let firstFill = fills.first {
                                print("📋 [DEBUG] Sample fill: \(firstFill.displayCoin) \(firstFill.displaySide) \(firstFill.sz) at \(firstFill.px)")
                            }
                        } else {
                            print("❌ [DEBUG] Invalid response format")
                            self.status = "❌ Invalid response format"
                        }
                    } catch {
                        print("❌ [DEBUG] JSON parsing error: \(error)")
                        self.status = "❌ Failed to parse response"
                    }
                }
            }.resume()
        }
    }
}