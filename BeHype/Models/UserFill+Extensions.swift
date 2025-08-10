import Foundation

extension UserFill {
    public var formattedDate: String {
        let date = Date(timeIntervalSince1970: TimeInterval(time) / 1000.0)
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    public var displayCoin: String {
        return coin == "@142" ? "BTC/USDC" : coin
    }
    
    public var isBuy: Bool {
        return side == "B" || dir == "Buy"
    }
    
    public var displaySide: String {
        return isBuy ? "Buy" : "Sell"
    }
    
    public var displayPrice: String {
        return "$\(px)"
    }
    
    public var displayAmount: String {
        return "\(sz) \(isBuy ? "USDC" : "BTC")"
    }
}