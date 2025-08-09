//
//  ChartView.swift
//  BeHype
//
//  BTC/USDC candlestick chart with Hyperliquid data
//

import Charts
import SwiftUI

struct CandlestickMark: ChartContent {
    let data: CandlestickData
    let width: CGFloat
    
    var body: some ChartContent {
        // High-Low wick
        RuleMark(
            x: .value("Date", data.timestamp),
            yStart: .value("Low", data.low),
            yEnd: .value("High", data.high)
        )
        .foregroundStyle(data.isBullish ? Color.bullishGreen : Color.bearishRed)
        .lineStyle(StrokeStyle(lineWidth: 1))
        
        // Open-Close body
        RectangleMark(
            x: .value("Date", data.timestamp),
            yStart: .value("Start", min(data.open, data.close)),
            yEnd: .value("End", max(data.open, data.close)),
            width: .fixed(width)
        )
        .foregroundStyle(data.isBullish ? Color.bullishGreen : Color.bearishRed)
    }
}

struct CandlestickChartView: View {
    @ObservedObject var hyperliquidService: HyperliquidService
    @Environment(\.dismiss) private var dismiss
    
    @State private var candlestickData: [CandlestickData] = []
    @State private var selectedData: CandlestickData?
    @State private var selectedTimeframe: ChartTimeframe = .oneHour
    @State private var isLoading = false
    
    var visibleData: [CandlestickData] {
        return candlestickData
    }
    
    var minPrice: Double {
        visibleData.map { $0.low }.min() ?? 0
    }
    
    var maxPrice: Double {
        visibleData.map { $0.high }.max() ?? 100
    }
    
    /// Calculate optimal spacing between candles based on count
    var candleSpacing: CGFloat {
        let count = visibleData.count
        if count < 20 {
            return 24  // Wide spacing for few candles
        } else if count < 50 {
            return 18  // Medium spacing
        } else if count < 100 {
            return 14  // Closer spacing for more candles
        } else {
            return 10  // Tight spacing for many candles
        }
    }
    
    /// Calculate candle width based on spacing
    var candleWidth: CGFloat {
        return max(6, candleSpacing - 4)  // Candle width is spacing minus 4px gap, minimum 6px
    }
    
    /// Calculate total chart width
    var chartWidth: CGFloat {
        let calculatedWidth = CGFloat(visibleData.count) * candleSpacing
        return max(350, calculatedWidth)  // Minimum width of 350px
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        headerView
                            .padding(.horizontal)
                        
                        timeframeSelector
                        
                        selectedCandleDetails
                        
                        chartSection
                        
                        chartLegend
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("BTC/USDC Chart")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.primaryText)
                }
            }
        }
        .onAppear {
            loadChartData()
        }
    }
    
    // MARK: - View Components
    
    private var headerView: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.25),
                                        Color.white.opacity(0.15),
                                        Color.white.opacity(0.1),
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 50, height: 50)
                            .overlay(
                                Circle()
                                    .strokeBorder(
                                        LinearGradient.beHypeBrand,
                                        lineWidth: 2
                                    )
                            )
                            .shadow(color: Color.blue.opacity(0.2), radius: 8, x: 0, y: 4)
                        
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(LinearGradient.beHypeBrand)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("BTC/USDC")
                            .sectionTitle()
                        
                        Text("Spot Market")
                            .secondaryText()
                    }
                    
                    Spacer()
                }
                
                if let latest = candlestickData.last {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Current Price")
                                .captionText()
                            Text("$\(latest.formattedClose)")
                                .largePriceText(color: latest.isBullish ? Color.bullishGreen : Color.bearishRed)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            HStack(spacing: 4) {
                                Image(systemName: latest.isBullish ? "arrow.up" : "arrow.down")
                                    .font(.caption)
                                Text(latest.formattedPercentChange)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(latest.isBullish ? Color.bullishGreen : Color.bearishRed)
                            
                            Text(latest.formattedChange)
                                .captionText()
                                .foregroundColor(latest.isBullish ? Color.bullishGreen : Color.bearishRed)
                        }
                    }
                }
            }
        }
    }
    
    private var timeframeSelector: some View {
        AppCard {
            VStack(spacing: 12) {
                HStack {
                    Text("Timeframe")
                        .inputLabel()
                    Spacer()
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(ChartTimeframe.allCases, id: \.self) { timeframe in
                            FilterButton(
                                title: timeframe.displayName,
                                isSelected: selectedTimeframe == timeframe
                            ) {
                                selectedTimeframe = timeframe
                                loadChartData()
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var selectedCandleDetails: some View {
        if let selected = selectedData {
            AppCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text(formatDate(selected.timestamp))
                        .cardTitle()
                    
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Open")
                                .captionText()
                            Text("$\(selected.formattedOpen)")
                                .priceText(color: Color.secondaryText)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("High")
                                .captionText()
                            Text("$\(selected.formattedHigh)")
                                .priceText(color: Color.bullishGreen)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Low")
                                .captionText()
                            Text("$\(selected.formattedLow)")
                                .priceText(color: Color.bearishRed)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Close")
                                .captionText()
                            Text("$\(selected.formattedClose)")
                                .priceText(color: selected.isBullish ? Color.bullishGreen : Color.bearishRed)
                        }
                    }
                    
                    HStack {
                        Text("Change: \(selected.formattedChange)")
                            .captionText()
                        Spacer()
                        Text("\(selected.formattedPercentChange)")
                            .captionText()
                            .foregroundColor(selected.isBullish ? Color.bullishGreen : Color.bearishRed)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    @ViewBuilder
    private var chartSection: some View {
        ZStack {
            if !candlestickData.isEmpty {
                HStack(spacing: 0) {
                    mainChart
                    yAxisChart
                }
                .padding(.horizontal)
            } else if !isLoading {
                emptyStateView
            }
            
            if isLoading {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .primaryGradientStart))
                                .scaleEffect(1.2)
                            Text("Loading chart data...")
                                .secondaryText()
                        }
                        .padding(20)
                        .background(
                            AppCard {
                                Color.clear
                            }
                        )
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
    }
    
    private var candlestickChart: some View {
        Chart(visibleData) { item in
            CandlestickMark(data: item, width: candleWidth)
            
            if item.id == selectedData?.id {
                RuleMark(x: .value("Selected", item.timestamp))
                    .foregroundStyle(.gray.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
            }
        }
    }
    
    private var chartModifiers: some View {
        candlestickChart
            .frame(width: chartWidth, height: 430)
            .chartYScale(domain: (minPrice * 0.98)...(maxPrice * 1.02))
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { value in
                    AxisGridLine()
                    AxisValueLabel(format: getXAxisFormat())
                }
            }
            .chartYAxis(.hidden)
    }
    
    private func chartBackground(geometry: GeometryProxy) -> some View {
        Rectangle()
            .fill(Color.clear)
            .contentShape(Rectangle())
            .onTapGesture { location in
                let xPosition = location.x
                let chartWidth = geometry.size.width
                let candleWidth = chartWidth / CGFloat(visibleData.count)
                let index = Int(xPosition / candleWidth)
                
                if index >= 0 && index < visibleData.count {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedData = visibleData[index]
                    }
                }
            }
    }
    
    private var mainChart: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                chartModifiers
                    .chartBackground { chartProxy in
                        GeometryReader { geometry in
                            chartBackground(geometry: geometry)
                        }
                    }
                Spacer()
            }
        }
        .clipped()
    }
    
    private var yAxisChart: some View {
        Chart(visibleData.prefix(1)) { item in
            PointMark(x: .value("Date", item.timestamp), y: .value("Price", item.close))
                .opacity(0)
        }
        .frame(width: 80, height: 430)
        .chartYScale(domain: (minPrice * 0.98)...(maxPrice * 1.02))
        .chartXAxis(.hidden)
        .chartYAxis {
            AxisMarks(position: .trailing) { value in
                AxisValueLabel()
            }
        }
        .background(Color.clear)
    }
    
    private var emptyStateView: some View {
        AppCard {
            VStack(spacing: 20) {
                Image(systemName: "chart.line.downtrend.xyaxis")
                    .font(.system(size: 60))
                    .foregroundColor(.tertiaryText)
                
                Text("No Chart Data")
                    .sectionTitle()
                
                Text("Fetching candle data from Hyperliquid...")
                    .secondaryText()
                    .multilineTextAlignment(.center)
                
                SmallButton("Refresh", icon: "arrow.clockwise") {
                    loadChartData()
                }
            }
            .padding(.vertical, 20)
        }
        .frame(height: 300)
        .padding(.horizontal)
    }
    
    private var chartLegend: some View {
        AppCard {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.secondaryText)
                Text("\(visibleData.count) candles")
                    .secondaryText()
                
                Spacer()
                
                Text("Tap candle for details")
                    .captionText()
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Private Methods
    
    private func loadChartData() {
        isLoading = true
        candlestickData = []
        selectedData = nil
        
        // Use the Hyperliquid service to get candle data
        Task {
            await MainActor.run {
                // Fetch candles from Hyperliquid
                let candles = self.hyperliquidService.getCandles(
                    interval: self.selectedTimeframe.rawValue,
                    hoursBack: self.selectedTimeframe.hoursToFetch
                )
                
                // Convert to our CandlestickData format
                let candlestickData = candles.map { candle in
                    CandlestickData(
                        timestamp: Date(timeIntervalSince1970: TimeInterval(candle.timeOpen) / 1000),
                        open: Double(candle.open) ?? 0,
                        high: Double(candle.high) ?? 0,
                        low: Double(candle.low) ?? 0,
                        close: Double(candle.close) ?? 0,
                        volume: Double(candle.volume) ?? 0
                    )
                }.sorted { $0.timestamp < $1.timestamp }
                
                withAnimation {
                    self.candlestickData = candlestickData
                    self.isLoading = false
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        
        switch selectedTimeframe {
        case .fifteenMinutes, .oneHour:
            formatter.dateFormat = "MMM d, HH:mm"
        case .fourHours:
            formatter.dateFormat = "MMM d, HH:mm"
        case .oneDay:
            formatter.dateFormat = "MMM d, yyyy"
        case .oneWeek:
            formatter.dateFormat = "MMM d, yyyy"
        }
        
        return formatter.string(from: date)
    }
    
    private func getXAxisFormat() -> Date.FormatStyle {
        switch selectedTimeframe {
        case .fifteenMinutes, .oneHour:
            return .dateTime.hour().minute()
        case .fourHours:
            return .dateTime.month(.abbreviated).day().hour()
        case .oneDay, .oneWeek:
            return .dateTime.month(.abbreviated).day()
        }
    }
}

#Preview {
    CandlestickChartView(hyperliquidService: HyperliquidService())
}