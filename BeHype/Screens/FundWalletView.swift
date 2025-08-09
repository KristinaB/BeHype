//
//  FundWalletView.swift
//  BeHype
//
//  Wallet funding view with QR code and address copying for Hyperliquid testnet
//

import SwiftUI

struct FundWalletView: View {
  @ObservedObject var hyperliquidService: HyperliquidService
  @Environment(\.dismiss) private var dismiss
  @State private var showingCopiedAlert = false
  
  var body: some View {
    NavigationView {
      ZStack {
        Color.appBackground
          .ignoresSafeArea()
        
        ScrollView {
          VStack(spacing: 32) {
            // Header
            headerView
            
            // QR Code section
            qrCodeSection
            
            // Wallet address section
            walletAddressSection
            
            // Network warning section
            networkWarningSection
            
            // Done button
            PrimaryButton("Done") {
              dismiss()
            }
            
            Spacer(minLength: 20)
          }
          .padding()
        }
      }
      .navigationTitle("Fund Wallet")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Done") {
            dismiss()
          }
          .foregroundColor(.primaryText)
        }
      }
      .alert("Address Copied!", isPresented: $showingCopiedAlert) {
        Button("OK") { }
      } message: {
        Text("The wallet address has been copied to your clipboard.")
      }
    }
  }
  
  // MARK: - View Components
  
  private var headerView: some View {
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
          .frame(width: 80, height: 80)
          .overlay(
            Circle()
              .strokeBorder(
                LinearGradient.beHypeBrand,
                lineWidth: 2
              )
          )
          .shadow(color: Color.blue.opacity(0.2), radius: 8, x: 0, y: 4)
        
        Image(systemName: "arrow.down.circle.fill")
          .font(.system(size: 36, weight: .medium))
          .foregroundStyle(LinearGradient.beHypeBrand)
      }
      
      Text("Fund Wallet")
        .brandText()
      
      Text("Send USDC to this address on Hyperliquid Testnet")
        .secondaryText()
        .multilineTextAlignment(.center)
    }
    .padding(.top, 20)
  }
  
  private var qrCodeSection: some View {
    AppCard {
      VStack(spacing: 20) {
        Text("Scan QR Code")
          .cardTitle()
        
        // QR Code placeholder - would need to implement QRCodeView
        RoundedRectangle(cornerRadius: 12)
          .fill(Color.white)
          .frame(width: 200, height: 200)
          .overlay(
            VStack {
              Image(systemName: "qrcode")
                .font(.system(size: 80))
                .foregroundColor(.gray)
              Text("QR Code")
                .font(.caption)
                .foregroundColor(.gray)
            }
          )
          .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        
        Text("Point your camera at this QR code")
          .captionText()
          .foregroundColor(.tertiaryText)
      }
    }
  }
  
  private var walletAddressSection: some View {
    AppCard {
      VStack(spacing: 16) {
        HStack {
          Text("Wallet Address")
            .cardTitle()
          
          Spacer()
          
          // Network badge
          Text("Testnet")
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
              RoundedRectangle(cornerRadius: 4)
                .fill(Color.orange.opacity(0.2))
            )
            .foregroundColor(.orange)
        }
        
        // Address display
        VStack(spacing: 12) {
          // Full address
          HStack {
            Text(getWalletAddress())
              .font(.system(.footnote, design: .monospaced))
              .secondaryText()
              .lineLimit(1)
              .truncationMode(.middle)
            
            Spacer()
          }
          .padding(12)
          .background(
            RoundedRectangle(cornerRadius: 8)
              .fill(Color.cardBackground.opacity(0.5))
          )
          
          // Copy button
          SecondaryButton("Copy Address") {
            copyAddress()
          }
        }
      }
    }
  }
  
  private var networkWarningSection: some View {
    AppCard {
      VStack(spacing: 12) {
        HStack {
          Image(systemName: "exclamationmark.triangle.fill")
            .font(.system(size: 20))
            .foregroundColor(.warningOrange)
          
          Text("Important")
            .cardTitle()
          
          Spacer()
        }
        
        VStack(alignment: .leading, spacing: 8) {
          Text("• Only send USDC to this address on Hyperliquid Testnet")
            .secondaryText()
          Text("• This is a testnet address - use only test funds")
            .secondaryText()
          Text("• Sending mainnet funds will result in permanent loss")
            .secondaryText()
          Text("• Always verify the address before sending")
            .secondaryText()
        }
      }
    }
  }
  
  // MARK: - Private Methods
  
  private func getWalletAddress() -> String {
    // Get the address from the Hyperliquid service
    // For now, return a placeholder - would need to get actual testnet address
    return hyperliquidService.testAddress.isEmpty ? "Loading..." : hyperliquidService.testAddress
  }
  
  private func copyAddress() {
    let address = getWalletAddress()
    UIPasteboard.general.string = address
    showingCopiedAlert = true
    
    // Haptic feedback
    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    impactFeedback.impactOccurred()
  }
}

#Preview {
  FundWalletView(hyperliquidService: HyperliquidService())
}