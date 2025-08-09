//
//  Colors.swift
//  BeHype
//
//  Centralized color palette for dark theme trading app 🎨✨
//

import SwiftUI

extension Color {
    // MARK: - App Colors
    
    /// App background colors
    static let appBackground = Color.black
    static let cardBackground = Color(red: 0.1, green: 0.1, blue: 0.1)
    static let inputBackground = Color(red: 0.15, green: 0.15, blue: 0.15)
    
    /// Text colors
    static let primaryText = Color.white
    static let secondaryText = Color(red: 0.7, green: 0.7, blue: 0.7)
    static let tertiaryText = Color(red: 0.5, green: 0.5, blue: 0.5)
    
    /// BeHype brand gradients - blue/green theme
    static let primaryGradientStart = Color.blue
    static let primaryGradientEnd = Color.green.opacity(0.8)
    static let accentGradientStart = Color.cyan
    static let accentGradientEnd = Color.mint.opacity(0.7)
    
    /// Border colors
    static let borderGray = Color(red: 0.3, green: 0.3, blue: 0.3)
    static let borderLight = Color(red: 0.4, green: 0.4, blue: 0.4)
    
    /// Status colors
    static let successGreen = Color.green
    static let bullishGreen = Color(red: 0.2, green: 0.8, blue: 0.4)
    static let warningOrange = Color.orange
    static let errorRed = Color.red
    static let bearishRed = Color(red: 0.8, green: 0.3, blue: 0.3)
    static let pendingBlue = Color.blue
    
    /// Chart colors
    static let chartLine = Color.blue
    static let chartFill = Color.blue.opacity(0.2)
}

// MARK: - Gradients

extension LinearGradient {
    /// Primary button gradient (blue to green)
    static let primaryButton = LinearGradient(
        colors: [Color.primaryGradientStart, Color.primaryGradientEnd],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    /// Accent button gradient (cyan to mint)
    static let accentButton = LinearGradient(
        colors: [Color.accentGradientStart, Color.accentGradientEnd],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    /// Card background gradient with glass effect
    static let cardBackground = LinearGradient(
        colors: [
            Color.white.opacity(0.05),
            Color.clear,
            Color.black.opacity(0.1)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// BeHype brand gradient
    static let beHypeBrand = LinearGradient(
        colors: [
            Color.blue,
            Color.cyan,
            Color.green
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}