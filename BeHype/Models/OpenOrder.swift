//
//  OpenOrder.swift
//  BeHype
//
//  Data model for open orders from Hyperliquid frontend API
//

import Foundation

public struct OpenOrder: Identifiable {
  public let id: UInt64
  public var children: [String]  // Array of frontend order IDs (if any)
  public var coin: String
  public var isPositionTpsl: Bool
  public var isTrigger: Bool
  public var limitPx: String
  public var oid: UInt64
  public var orderType: String
  public var origSz: String
  public var reduceOnly: Bool
  public var side: String  // "A" or "B"
  public var sz: String
  public var tif: String
  public var timestamp: UInt64
  public var triggerCondition: String
  public var triggerPx: String
  
  public init(
    children: [String], 
    coin: String, 
    isPositionTpsl: Bool, 
    isTrigger: Bool, 
    limitPx: String, 
    oid: UInt64, 
    orderType: String, 
    origSz: String, 
    reduceOnly: Bool, 
    side: String, 
    sz: String, 
    tif: String, 
    timestamp: UInt64, 
    triggerCondition: String, 
    triggerPx: String
  ) {
    self.id = oid
    self.children = children
    self.coin = coin
    self.isPositionTpsl = isPositionTpsl
    self.isTrigger = isTrigger
    self.limitPx = limitPx
    self.oid = oid
    self.orderType = orderType
    self.origSz = origSz
    self.reduceOnly = reduceOnly
    self.side = side
    self.sz = sz
    self.tif = tif
    self.timestamp = timestamp
    self.triggerCondition = triggerCondition
    self.triggerPx = triggerPx
  }
}

// Extension to provide computed properties for display
extension OpenOrder {
  public var displayCoin: String {
    if coin == "@142" {
      return "BTC/USDC"
    }
    return coin
  }
  
  public var displaySide: String {
    return side == "B" ? "Buy" : "Sell"
  }
  
  public var displayStatus: String {
    return "Pending"
  }
  
  public var displayDate: String {
    let date = Date(timeIntervalSince1970: TimeInterval(timestamp) / 1000.0)
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter.string(from: date)
  }
  
  public var displayOrderType: String {
    if isTrigger {
      return "Stop/Trigger"
    } else if limitPx != "0" {
      return "Limit"
    } else {
      return "Market"
    }
  }
}