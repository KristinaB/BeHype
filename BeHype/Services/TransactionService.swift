//
//  TransactionService.swift
//  BeHype
//
//  Service for managing transaction history and user fills
//

import Foundation
import SwiftUI

class TransactionService: ObservableObject {
  @Published var userFills: [UserFill] = []
  @Published var openOrders: [OpenOrder] = []
  @Published var isLoading: Bool = false
  @Published var status: String = ""

  private weak var walletService: WalletService?

  init(walletService: WalletService) {
    self.walletService = walletService
  }

  func fetchOpenOrders() {
    print("🔍 [TransactionService] Starting fetchOpenOrders...")
    
    // Check if running in UI test mock mode
    if MockManager.shared.isUITestMockMode {
      print("🧪 [UI TEST] Using mock open orders data")
      let mockOrders = MockManager.shared.generateMockOpenOrders()
      
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        self.openOrders = mockOrders
        self.status = "✅ Found \(mockOrders.count) mock open orders"
      }
      return
    }
    
    guard let walletService = walletService,
          !walletService.walletAddress.isEmpty
    else {
      print("❌ [TransactionService] Wallet address is empty")
      status = "❌ Wallet not loaded"
      return
    }
    
    isLoading = true
    status = "🔍 Fetching open orders..."
    
    DispatchQueue.global(qos: .background).async {
      let requestBody: [String: Any] = [
        "type": "frontendOpenOrders",
        "user": walletService.walletAddress,
        "dex": ""
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
            print("❌ [TransactionService] Network error: \(error)")
            self.status = "❌ Network error"
            return
          }
          
          guard let data = data else {
            print("❌ [TransactionService] No data received")
            self.status = "❌ No data received"
            return
          }
          
          do {
            if let ordersArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
              print("✅ [TransactionService] Received \(ordersArray.count) open orders")
              
              let orders = ordersArray.compactMap { orderData -> OpenOrder? in
                guard let coin = orderData["coin"] as? String,
                      let limitPx = orderData["limitPx"] as? String,
                      let oid = orderData["oid"] as? UInt64,
                      let orderType = orderData["orderType"] as? String,
                      let origSz = orderData["origSz"] as? String,
                      let side = orderData["side"] as? String,
                      let sz = orderData["sz"] as? String,
                      let tif = orderData["tif"] as? String,
                      let timestamp = orderData["timestamp"] as? UInt64
                else {
                  print("⚠️ [TransactionService] Skipping malformed open order data")
                  return nil
                }
                
                let children = orderData["children"] as? [String] ?? []
                let isPositionTpsl = orderData["isPositionTpsl"] as? Bool ?? false
                let isTrigger = orderData["isTrigger"] as? Bool ?? false
                let reduceOnly = orderData["reduceOnly"] as? Bool ?? false
                let triggerCondition = orderData["triggerCondition"] as? String ?? ""
                let triggerPx = orderData["triggerPx"] as? String ?? ""
                
                return OpenOrder(
                  children: children,
                  coin: coin,
                  isPositionTpsl: isPositionTpsl,
                  isTrigger: isTrigger,
                  limitPx: limitPx,
                  oid: oid,
                  orderType: orderType,
                  origSz: origSz,
                  reduceOnly: reduceOnly,
                  side: side,
                  sz: sz,
                  tif: tif,
                  timestamp: timestamp,
                  triggerCondition: triggerCondition,
                  triggerPx: triggerPx
                )
              }
              
              self.openOrders = orders
              self.status = "✅ Found \(orders.count) open orders"
              
              // Log first order for debugging
              if let firstOrder = orders.first {
                print(
                  "🔍 [TransactionService] Sample order: \(firstOrder.displayCoin) \(firstOrder.displaySide) \(firstOrder.sz) at \(firstOrder.limitPx)"
                )
              }
            } else {
              print("❌ [TransactionService] Invalid response format")
              self.status = "❌ Invalid response format"
            }
          } catch {
            print("❌ [TransactionService] JSON parsing error: \(error)")
            self.status = "❌ Failed to parse response"
          }
        }
      }.resume()
    }
  }

  func fetchUserFills(daysBack: Int = 30) {
    print("📋 [TransactionService] Starting fetchUserFills...")

    // Check if running in UI test mock mode
    if MockManager.shared.isUITestMockMode {
      print("🧪 [UI TEST] Using mock user fills data")
      let mockFills = MockManager.shared.generateMockTransactions()

      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        self.userFills = mockFills
        self.status = "✅ Found \(mockFills.count) mock fills"
      }
      return
    }

    guard let walletService = walletService,
      !walletService.walletAddress.isEmpty
    else {
      print("❌ [TransactionService] Wallet address is empty")
      status = "❌ Wallet not loaded"
      return
    }

    isLoading = true
    status = "📋 Fetching user fills..."

    DispatchQueue.global(qos: .background).async {
      let currentTime = UInt64(Date().timeIntervalSince1970 * 1000)  // milliseconds
      let startTime = currentTime - UInt64(daysBack * 24 * 60 * 60 * 1000)  // days ago

      let requestBody: [String: Any] = [
        "type": "userFillsByTime",
        "user": walletService.walletAddress,
        "startTime": startTime,
        "endTime": currentTime,
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
            print("❌ [TransactionService] Network error: \(error)")
            self.status = "❌ Network error"
            return
          }

          guard let data = data else {
            print("❌ [TransactionService] No data received")
            self.status = "❌ No data received"
            return
          }

          do {
            if let fillsArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
              print("✅ [TransactionService] Received \(fillsArray.count) fills")

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
                  let crossed = fillData["crossed"] as? Bool
                else {
                  print("⚠️ [TransactionService] Skipping malformed fill data")
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
                print(
                  "📋 [TransactionService] Sample fill: \(firstFill.displayCoin) \(firstFill.displaySide) \(firstFill.sz) at \(firstFill.px)"
                )
              }
            } else {
              print("❌ [TransactionService] Invalid response format")
              self.status = "❌ Invalid response format"
            }
          } catch {
            print("❌ [TransactionService] JSON parsing error: \(error)")
            self.status = "❌ Failed to parse response"
          }
        }
      }.resume()
    }
  }
}
