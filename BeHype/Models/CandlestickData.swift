//
//  CandlestickData.swift
//  BeHype
//
//  OHLC candlestick data model for BTC/USDC charts
//

import Foundation

/// OHLC candlestick data point
struct CandlestickData: Identifiable, Equatable {
    let id: UUID
    let timestamp: Date
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Double
    
    init(timestamp: Date, open: Double, high: Double, low: Double, close: Double, volume: Double = 0) {
        self.id = UUID()
        self.timestamp = timestamp
        self.open = open
        self.high = high
        self.low = low
        self.close = close
        self.volume = volume
    }
    
    /// Price change from open to close
    var priceChange: Double {
        return close - open
    }
    
    /// Percentage change from open to close
    var percentageChange: Double {
        guard open != 0 else { return 0 }
        return (priceChange / open) * 100
    }
    
    /// Is this a bullish (green) candle?
    var isBullish: Bool {
        return close >= open
    }
    
    /// Formatted price strings
    var formattedOpen: String { 
        return formatPrice(open)
    }
    
    var formattedHigh: String { 
        return formatPrice(high)
    }
    
    var formattedLow: String { 
        return formatPrice(low)
    }
    
    var formattedClose: String { 
        return formatPrice(close)
    }
    
    var formattedVolume: String { 
        return String(format: "%.2f", volume)
    }
    
    var formattedChange: String { 
        let sign = priceChange >= 0 ? "+" : ""
        return "\(sign)\(formatPrice(priceChange))"
    }
    
    var formattedPercentChange: String {
        let sign = percentageChange >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", percentageChange))%"
    }
    
    private func formatPrice(_ price: Double) -> String {
        // For BTC prices, use comma formatting
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: price)) ?? String(format: "%.2f", price)
    }
    
    // Custom Equatable implementation (excluding UUID)
    static func == (lhs: CandlestickData, rhs: CandlestickData) -> Bool {
        return lhs.timestamp == rhs.timestamp &&
               lhs.open == rhs.open &&
               lhs.high == rhs.high &&
               lhs.low == rhs.low &&
               lhs.close == rhs.close &&
               lhs.volume == rhs.volume
    }
}

/// Chart time intervals
enum ChartTimeframe: String, CaseIterable {
    case fifteenMinutes = "15m"
    case oneHour = "1h"
    case fourHours = "4h"
    case oneDay = "1d"
    
    var displayName: String {
        switch self {
        case .fifteenMinutes: return "15M"
        case .oneHour: return "1H"
        case .fourHours: return "4H"
        case .oneDay: return "1D"
        }
    }
    
    /// Get the duration in hours for fetching candle data
    var hoursToFetch: Int {
        switch self {
        case .fifteenMinutes: return 24      // 24 hours of 15m candles
        case .oneHour: return 24 * 7         // 1 week of hourly candles
        case .fourHours: return 24 * 30      // 1 month of 4h candles
        case .oneDay: return 24 * 90         // 3 months of daily candles
        }
    }
}