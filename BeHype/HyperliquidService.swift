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
    private var testPrivateKey: String?
    private var testAddress: String = ""
    
    init() {
        setupSDK()
    }
    
    private func setupSDK() {
        self.sdk = HyperliquidSwiftSDK()
        self.client = sdk?.createClient()
        status = "SDK initialized"
    }
    
    func loadPrivateKey() {
        guard let keyPath = Bundle.main.path(forResource: "private-key", ofType: "key"),
              let key = try? String(contentsOfFile: keyPath).trimmingCharacters(in: .whitespacesAndNewlines) else {
            status = "Private key not found. Add private-key.key to bundle"
            return
        }
        
        let cleanKey = key.hasPrefix("0x") ? String(key.dropFirst(2)) : key
        self.testPrivateKey = cleanKey
        
        if let sdk = sdk {
            self.walletClient = sdk.createClientWithWallet(privateKey: cleanKey)
            self.testAddress = sdk.deriveAddress(from: cleanKey)
            status = "Wallet loaded: \(String(testAddress.prefix(10)))..."
        }
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
        guard let walletClient = walletClient, !testAddress.isEmpty else {
            status = "❌ Wallet not loaded"
            return
        }
        
        isLoading = true
        status = "Checking balances..."
        
        DispatchQueue.global(qos: .background).async {
            let balances = walletClient.getTokenBalances(address: self.testAddress)
            
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
    
    func runFullDemo() {
        loadPrivateKey()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.fetchExchangeData()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.checkBalance()
        }
    }
}