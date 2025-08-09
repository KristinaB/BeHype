import Foundation
import SwiftUI

class HyperliquidService: ObservableObject {
    @Published var status: String = "Ready"
    @Published var isLoading: Bool = false
    @Published var exchangeAssets: Int = 0
    @Published var usdcBalance: String = "0.0"
    @Published var btcPrice: String = "0.0"
    @Published var lastSwapResult: String = ""
    
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
            
            let meta = client.getExchangeMeta()
            let prices = client.getAllMids()
            
            DispatchQueue.main.async {
                self.exchangeAssets = Int(meta.totalAssets)
                
                if let btcPriceData = prices.first(where: { $0.coin == "BTC" }) {
                    self.btcPrice = String(format: "%.2f", btcPriceData.price)
                }
                
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
                if let usdcBalance = balances.first(where: { $0.coin == "USDC" }) {
                    self.usdcBalance = usdcBalance.total
                    self.status = "💵 USDC Balance: \(usdcBalance.total)"
                } else {
                    self.usdcBalance = "0.0"
                    self.status = "❌ No USDC balance found"
                }
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
}