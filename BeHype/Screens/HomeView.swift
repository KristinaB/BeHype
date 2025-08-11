//
//  HomeView.swift
//  BeHype
//
//  Trading app home screen with portfolio and market overview
//

import SwiftUI

struct HomeView: View {
  @ObservedObject var hyperliquidService: HyperliquidService
  @State private var showingDebugActions = false
  @State private var showingChart = false
  @State private var showingFundWallet = false
  @State private var selectedAsset: AssetData?

  var body: some View {
    NavigationView {
      ZStack {
        Color.appBackground
          .ignoresSafeArea()

        ScrollView {
          VStack(spacing: 24) {
            // App Branding Header
            brandingHeader

            // Portfolio Overview
            portfolioSection

            // Market Data
            marketDataSection

            // Asset Selector
            assetSelectorSection

            // NOTE: Nice UI sections but at the moment we don't need them

            // // Quick Actions
            // quickActionsSection

            // // Status Information
            // statusSection

            Spacer(minLength: 100)
          }
          .padding()
        }
      }
      .navigationTitle("")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          IconButton(icon: "gearshape.fill") {
            showingDebugActions.toggle()
          }
        }
      }
      .sheet(isPresented: $showingDebugActions) {
        DebugActionsView(hyperliquidService: hyperliquidService)
      }
      .sheet(isPresented: $showingChart) {
        CandlestickChartView(hyperliquidService: hyperliquidService)
      }
      .sheet(isPresented: $showingFundWallet) {
        FundWalletView(hyperliquidService: hyperliquidService)
      }
    }
    .onAppear {
      loadInitialData()
    }
  }

  // MARK: - View Components

  private var brandingHeader: some View {
    VStack(spacing: 16) {
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
          .frame(width: 100, height: 100)
          .overlay(
            Circle()
              .strokeBorder(
                LinearGradient.beHypeBrand,
                lineWidth: 3
              )
          )
          .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)

        Image(systemName: "chart.line.uptrend.xyaxis")
          .font(.system(size: 48, weight: .medium))
          .foregroundStyle(LinearGradient.beHypeBrand)
      }

      VStack(spacing: 4) {
        Text("BeHype")
          .brandText()

        Text("Open Source Swift Hyperliquid Trading App")
          .secondaryText()
      }

      // Fund Wallet Button
      HStack {
        Spacer()
        OutlineButton(
          "Fund Wallet",
          icon: "plus.circle.fill",
          size: .large
        ) {
          showingFundWallet.toggle()
        }
        Spacer()
      }
      .padding(.bottom, 8)
    }
  }

  private var portfolioSection: some View {
    VStack(spacing: 16) {
      PortfolioCard(
        title: "USDC Balance",
        balance: hyperliquidService.usdcBalance,
        value: "$\(hyperliquidService.usdcBalance)",
        change: nil,
        isPositive: nil
      )

      PortfolioCard(
        title: "BTC Balance",
        balance: hyperliquidService.btcBalance,
        value: "$\(calculateBtcValue())",
        change: nil,
        isPositive: nil
      )

      PortfolioCard(
        title: "Total Portfolio Value",
        balance: "$\(calculateTotalValue())",
        value: "USDC + BTC",
        change: nil,
        isPositive: nil
      )
    }
  }

  private var marketDataSection: some View {
    VStack(spacing: 16) {
      HStack {
        Text("Markets")
          .sectionTitle()
        Spacer()
      }

      VStack(spacing: 12) {
        MarketCardWithChart(
          symbol: "BTC/USDC",
          price: "$\(hyperliquidService.btcPrice)",
          change: "+2.1%",
          isPositive: true
        ) {
          showingChart.toggle()
        }

        // NOTE: hidden , we don't need to show exchange assets as they are internal identifiers
        //
        // MarketCard(
        //   symbol: "Exchange Assets",
        //   price: "\(hyperliquidService.exchangeAssets)",
        //   change: "Available",
        //   isPositive: true
        // )
      }
    }
  }

  private var assetSelectorSection: some View {
    VStack(spacing: 16) {
      HStack {
        Text("Switch to Asset")
          .sectionTitle()
        Spacer()

        if !hyperliquidService.availableAssets.isEmpty {
          Text("\(hyperliquidService.availableAssets.count) available")
            .captionText()
            .foregroundColor(.tertiaryText)
        }
      }

      AppCard {
        VStack(spacing: 16) {
          if hyperliquidService.availableAssets.isEmpty {
            HStack {
              ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .primaryGradientStart))
                .scaleEffect(0.8)
              Text("Loading assets...")
                .secondaryText()
            }
            .frame(maxWidth: .infinity)
            .padding()
          } else {
            VStack(spacing: 12) {
              HStack {
                Text("Choose an asset to trade:")
                  .inputLabel()
                Spacer()
              }

              // Use Menu for asset selection
              Menu {
                ForEach(hyperliquidService.availableAssets, id: \.id) { asset in
                  Button(action: {
                    selectedAsset = asset
                    print("📊 [HomeView] Selected asset: \(asset.name) - $\(asset.price)")
                  }) {
                    Label {
                      HStack {
                        Text(asset.name)
                        Spacer()
                        Text("$\(asset.price)")
                      }
                    } icon: {
                      EmptyView()
                    }
                  }
                }
              } label: {
                HStack {
                  VStack(alignment: .leading, spacing: 4) {
                    if let selectedAsset = selectedAsset {
                      Text(selectedAsset.name)
                        .font(.body)
                        .foregroundColor(.primaryText)
                      Text("$\(selectedAsset.price)")
                        .font(.caption)
                        .foregroundColor(.bullishGreen)
                    } else {
                      Text("Select an asset...")
                        .foregroundColor(.tertiaryText)
                    }
                  }

                  Spacer()

                  Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundColor(.primaryGradientStart)
                }
                .padding()
                .background(Color.inputBackground)
                .overlay(
                  RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(
                      LinearGradient(
                        colors: [
                          Color.primaryGradientStart.opacity(0.3),
                          Color.primaryGradientEnd.opacity(0.3),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                      ),
                      lineWidth: 1
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
              }
              .menuStyle(DefaultMenuStyle())
              
              // Switch Asset Button
              if let selectedAsset = selectedAsset {
                VStack(spacing: 8) {
                  Divider()
                    .background(Color.borderGray.opacity(0.3))
                  
                  OutlineButton(
                    "Switch to \(selectedAsset.name)",
                    icon: "arrow.triangle.2.circlepath",
                    size: .medium
                  ) {
                    // Confirmation action - currently does nothing
                    print("📊 [HomeView] User confirmed switch to \(selectedAsset.name) at $\(selectedAsset.price)")
                    
                    // TODO: Implement asset switching logic here
                    // This could update the trading pair in TradeView, 
                    // change the main market display, etc.
                  }
                  
                  Text("This will switch the main trading pair")
                    .captionText()
                    .foregroundColor(.tertiaryText)
                    .multilineTextAlignment(.center)
                }
                .padding(.top, 8)
              }
            }
          }
        }
      }
    }
  }

  // private var quickActionsSection: some View {
  //   VStack(spacing: 16) {
  //     HStack {
  //       Text("Quick Actions")
  //         .sectionTitle()
  //       Spacer()
  //     }

  //     VStack(spacing: 12) {
  //       ActionCard(
  //         icon: "chart.bar.fill",
  //         title: "Fetch Market Data",
  //         subtitle: "Get latest prices and exchange info"
  //       ) {
  //         hyperliquidService.fetchExchangeData()
  //       }

  //       ActionCard(
  //         icon: "dollarsign.circle.fill",
  //         title: "Check Balance",
  //         subtitle: "View your current USDC balance"
  //       ) {
  //         hyperliquidService.checkBalance()
  //       }

  //       ActionCard(
  //         icon: "chart.line.uptrend.xyaxis",
  //         title: "Get Chart Data",
  //         subtitle: "Fetch BTC/USDC candle data"
  //       ) {
  //         hyperliquidService.getCandleData()
  //       }

  //       if Double(hyperliquidService.usdcBalance) ?? 0 >= 11 {
  //         ActionCard(
  //           icon: "arrow.triangle.2.circlepath",
  //           title: "Quick Swap",
  //           subtitle: "Swap $11 USDC → BTC"
  //         ) {
  //           hyperliquidService.performSwap()
  //         }
  //       }
  //     }
  //   }
  // }

  // private var statusSection: some View {
  //   AppCard {
  //     VStack(alignment: .leading, spacing: 12) {
  //       HStack {
  //         Text("System Status")
  //           .cardTitle()

  //         Spacer()

  //         if hyperliquidService.isLoading {
  //           ProgressView()
  //             .progressViewStyle(CircularProgressViewStyle(tint: .primaryGradientStart))
  //             .scaleEffect(0.8)
  //         }
  //       }

  //       Text(hyperliquidService.status)
  //         .secondaryText()
  //         .multilineTextAlignment(.leading)

  //       if !hyperliquidService.lastSwapResult.isEmpty {
  //         Divider()
  //           .background(Color.borderGray.opacity(0.3))

  //         VStack(alignment: .leading, spacing: 8) {
  //           Text("Last Transaction:")
  //             .inputLabel()

  //           Text(hyperliquidService.lastSwapResult)
  //             .captionText()
  //             .multilineTextAlignment(.leading)
  //         }
  //       }
  //     }
  //   }
  // }

  // MARK: - Private Methods

  private func loadInitialData() {
    Task {
      hyperliquidService.loadPrivateKey()
      await MainActor.run {
        hyperliquidService.fetchExchangeData()
        hyperliquidService.checkBalance()
      }
    }
  }

  private func calculateTotalValue() -> String {
    let usdcValue = Double(hyperliquidService.usdcBalance) ?? 0
    let btcAmount = Double(hyperliquidService.btcBalance) ?? 0
    let btcPrice = Double(hyperliquidService.btcPrice) ?? 0
    let btcValue = btcAmount * btcPrice
    let total = usdcValue + btcValue
    return String(format: "%.2f", total)
  }

  private func calculateBtcValue() -> String {
    let btcAmount = Double(hyperliquidService.btcBalance) ?? 0
    let btcPrice = Double(hyperliquidService.btcPrice) ?? 0
    let btcValue = btcAmount * btcPrice
    return String(format: "%.2f", btcValue)
  }
}

// MARK: - Debug Actions View

struct DebugActionsView: View {
  @ObservedObject var hyperliquidService: HyperliquidService
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationView {
      ZStack {
        Color.appBackground
          .ignoresSafeArea()

        VStack(spacing: 20) {
          Text("Debug Actions")
            .sectionTitle()

          VStack(spacing: 12) {
            PrimaryButton("🚀 Run Full Demo", isLoading: hyperliquidService.isLoading) {
              hyperliquidService.runFullDemo()
            }

            SecondaryButton("📊 Fetch Exchange Data", isLoading: hyperliquidService.isLoading) {
              hyperliquidService.fetchExchangeData()
            }

            SecondaryButton("💰 Check Balance", isLoading: hyperliquidService.isLoading) {
              hyperliquidService.checkBalance()
            }

            SecondaryButton("📈 Get Candle Data", isLoading: hyperliquidService.isLoading) {
              hyperliquidService.getCandleData()
            }

            if Double(hyperliquidService.usdcBalance) ?? 0 >= 11 {
              PrimaryButton(
                "🔄 Swap $11 USDC → BTC",
                isLoading: hyperliquidService.isLoading
              ) {
                hyperliquidService.performSwap()
              }
            }
          }

          Spacer()

          Text("⚠️ Live trading - Mainnet")
            .captionText()
            .foregroundColor(.warningOrange)
            .multilineTextAlignment(.center)
        }
        .padding()
      }
      .navigationTitle("Debug")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Done") {
            dismiss()
          }
        }
      }
    }
  }
}

#Preview {
  HomeView(hyperliquidService: HyperliquidService())
}
