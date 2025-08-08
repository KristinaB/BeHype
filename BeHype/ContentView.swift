//
//  ContentView.swift
//  BeHype
//
//  Created by Kristina Canessa on 06/08/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var hyperliquidService = HyperliquidService()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                
                Image(systemName: "bitcoinsign.circle.fill")
                    .imageScale(.large)
                    .foregroundStyle(.orange)
                    .font(.system(size: 60))
                
                Text("BeHype")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Hyperliquid Trading Demo")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Divider()
                
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Status:")
                            .fontWeight(.semibold)
                        Spacer()
                        if hyperliquidService.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                    
                    Text(hyperliquidService.status)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                    
                    if hyperliquidService.exchangeAssets > 0 {
                        Group {
                            Text("Exchange Assets: \(hyperliquidService.exchangeAssets)")
                            Text("BTC Price: $\(hyperliquidService.btcPrice)")
                            Text("USDC Balance: \(hyperliquidService.usdcBalance)")
                        }
                        .font(.caption)
                    }
                    
                    if !hyperliquidService.lastSwapResult.isEmpty {
                        Text("Last Swap:")
                            .fontWeight(.semibold)
                        Text(hyperliquidService.lastSwapResult)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                VStack(spacing: 12) {
                    Button("🚀 Run Full Demo") {
                        hyperliquidService.runFullDemo()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(hyperliquidService.isLoading)
                    
                    HStack(spacing: 15) {
                        Button("📊 Fetch Data") {
                            hyperliquidService.fetchExchangeData()
                        }
                        .buttonStyle(.bordered)
                        .disabled(hyperliquidService.isLoading)
                        
                        Button("💰 Check Balance") {
                            hyperliquidService.checkBalance()
                        }
                        .buttonStyle(.bordered)
                        .disabled(hyperliquidService.isLoading)
                    }
                    
                    Button("📈 Get Chart Data") {
                        hyperliquidService.getCandleData()
                    }
                    .buttonStyle(.bordered)
                    .disabled(hyperliquidService.isLoading)
                    
                    Button("🔄 Swap $11 USDC → BTC") {
                        hyperliquidService.performSwap()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .disabled(hyperliquidService.isLoading || Double(hyperliquidService.usdcBalance) ?? 0 < 11)
                }
                
                Spacer()
                
                Text("⚠️ Demo mode - Use test funds only")
                    .font(.caption2)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .navigationTitle("BeHype")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
  ContentView()
}
