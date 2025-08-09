//
//  ContentView.swift
//  BeHype
//
//  Created by Kristina Canessa on 06/08/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var hyperliquidService = HyperliquidService()
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            // Dark background
            Color.appBackground
                .ignoresSafeArea()
            
            TabView(selection: $selectedTab) {
                HomeView(hyperliquidService: hyperliquidService)
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Home")
                    }
                    .tag(0)
                
                TradeView(hyperliquidService: hyperliquidService)
                    .tabItem {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                        Text("Trade")
                    }
                    .tag(1)
                
                TransactionsView(hyperliquidService: hyperliquidService)
                    .tabItem {
                        Image(systemName: "list.bullet.rectangle")
                        Text("Transactions")
                    }
                    .tag(2)
            }
            .accentColor(.primaryGradientStart)
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
  ContentView()
}
