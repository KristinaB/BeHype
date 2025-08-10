//
//  WalletService.swift
//  BeHype
//
//  Service for managing wallet operations and balances
//

import Foundation
import SwiftUI

class WalletService: ObservableObject {
  @Published var usdcBalance: String = "0.0"
  @Published var btcBalance: String = "0.0"
  @Published var walletAddress: String = ""
  @Published var isLoading: Bool = false
  @Published var status: String = ""

  private var sdk: HyperliquidSwiftSDK?
  private var walletClient: HyperliquidClient?
  private var privateKey: String?

  init() {
    self.sdk = HyperliquidSwiftSDK()
  }

  func loadPrivateKey() {
    print("🔐 [WalletService] Starting loadPrivateKey...")

    guard let keyPath = Bundle.main.path(forResource: "private-key", ofType: "key") else {
      print("❌ [WalletService] Bundle.main.path returned nil for private-key.key")
      status = "Private key file not found in bundle"
      return
    }

    print("✅ [WalletService] Found key path: \(keyPath)")

    guard
      let key = try? String(contentsOfFile: keyPath, encoding: .utf8).trimmingCharacters(
        in: .whitespacesAndNewlines)
    else {
      print("❌ [WalletService] Failed to read file at path: \(keyPath)")
      status = "Failed to read private key file"
      return
    }

    print("✅ [WalletService] Successfully read key file, length: \(key.count)")

    let cleanKey = key.hasPrefix("0x") ? String(key.dropFirst(2)) : key
    print("🔧 [WalletService] Cleaned key length: \(cleanKey.count)")
    self.privateKey = cleanKey

    guard let sdk = sdk else {
      print("❌ [WalletService] SDK is nil!")
      status = "SDK not initialized"
      return
    }

    print("🚀 [WalletService] Creating wallet client...")
    self.walletClient = sdk.createClientWithWallet(privateKey: cleanKey)

    print("🏠 [WalletService] Deriving address...")
    self.walletAddress = sdk.deriveAddress(from: cleanKey)

    print("✅ [WalletService] Wallet setup complete. Address: \(walletAddress)")
    status = "Wallet loaded: \(String(walletAddress.prefix(10)))..."
  }

  func checkBalance() {
    print("💰 [WalletService] Starting checkBalance...")
    print("💰 [WalletService] walletClient: \(walletClient != nil ? "✅ Present" : "❌ Nil")")
    print("💰 [WalletService] walletAddress: '\(walletAddress)' (isEmpty: \(walletAddress.isEmpty))")

    // If wallet not loaded, try loading it first
    if walletClient == nil || walletAddress.isEmpty {
      print("⚠️ [WalletService] Wallet not loaded, attempting to load now...")
      loadPrivateKey()

      // Check again after loading
      print("🔄 [WalletService] After loadPrivateKey:")
      print("    walletClient: \(walletClient != nil ? "✅ Present" : "❌ Nil")")
      print("    walletAddress: '\(walletAddress)' (isEmpty: \(walletAddress.isEmpty))")
    }

    guard let walletClient = walletClient, !walletAddress.isEmpty else {
      print("❌ [WalletService] Guard failed - wallet not properly loaded even after attempt")
      status = "❌ Wallet not loaded - check console logs"
      return
    }

    print("✅ [WalletService] Wallet client and address OK, proceeding...")
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

  // Get the wallet client for other services to use
  func getWalletClient() -> HyperliquidClient? {
    return walletClient
  }

  // Check if wallet is ready
  func isWalletReady() -> Bool {
    return walletClient != nil && !walletAddress.isEmpty
  }
}
