import Foundation

public struct UserFill {
    public let coin: String
    public let px: String
    public let sz: String
    public let side: String
    public let time: UInt64
    public let startPosition: String
    public let dir: String
    public let closedPnl: String
    public let hash: String
    public let oid: UInt64
    public let crossed: Bool
    public let fee: String?
    public let tid: UInt64?
    public let feeToken: String?
    
    public init(
        coin: String,
        px: String,
        sz: String,
        side: String,
        time: UInt64,
        startPosition: String,
        dir: String,
        closedPnl: String,
        hash: String,
        oid: UInt64,
        crossed: Bool,
        fee: String? = nil,
        tid: UInt64? = nil,
        feeToken: String? = nil
    ) {
        self.coin = coin
        self.px = px
        self.sz = sz
        self.side = side
        self.time = time
        self.startPosition = startPosition
        self.dir = dir
        self.closedPnl = closedPnl
        self.hash = hash
        self.oid = oid
        self.crossed = crossed
        self.fee = fee
        self.tid = tid
        self.feeToken = feeToken
    }
}

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