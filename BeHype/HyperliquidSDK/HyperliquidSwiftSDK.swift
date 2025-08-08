// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

public class HyperliquidSwiftSDK {
    
    public init() {}
    
    public func sayHello() -> String {
        return helloHyperliquid()
    }
    
    public func createClient() -> HyperliquidClient {
        return HyperliquidClient()
    }
    
    public func createClientWithWallet(privateKey: String) -> HyperliquidClient {
        return HyperliquidClient.newWithWallet(privateKey: privateKey)
    }
    
    public func deriveAddress(from privateKey: String) -> String {
        return deriveAddressFromPrivateKey(privateKey: privateKey)
    }
}
