//
//  Typography.swift
//  BeHype
//
//  Consistent typography styles for dark theme trading app 📝✨
//

import SwiftUI

// MARK: - Text Extensions

extension Text {
  /// Large title with primary color
  func appTitle() -> some View {
    self
      .font(.largeTitle)
      .fontWeight(.bold)
      .foregroundColor(.primaryText)
  }

  /// Section title
  func sectionTitle() -> some View {
    self
      .font(.title2)
      .fontWeight(.semibold)
      .foregroundColor(.primaryText)
  }

  /// Card title
  func cardTitle() -> some View {
    self
      .font(.headline)
      .foregroundColor(.primaryText)
  }

  /// Body text
  func bodyText() -> some View {
    self
      .font(.body)
      .foregroundColor(.primaryText)
  }

  /// Secondary text
  func secondaryText() -> some View {
    self
      .font(.subheadline)
      .foregroundColor(.secondaryText)
  }

  /// Caption text
  func captionText() -> some View {
    self
      .font(.caption)
      .foregroundColor(.tertiaryText)
  }

  /// Price text with formatting
  func priceText(color: Color = .primaryText) -> some View {
    self
      .font(.headline)
      .fontWeight(.medium)
      .foregroundColor(color)
  }

  /// Large price display
  func largePriceText(color: Color = .primaryText) -> some View {
    self
      .font(.title)
      .fontWeight(.semibold)
      .foregroundColor(color)
  }

  /// Status text with badge styling
  func statusText(status: StatusType) -> some View {
    self
      .font(.caption)
      .fontWeight(.medium)
      .foregroundColor(.white)
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .background(
        Capsule()
          .fill(status.color)
      )
  }

  /// Brand text with gradient
  func brandText() -> some View {
    self
      .font(.title)
      .fontWeight(.bold)
      .foregroundStyle(LinearGradient.beHypeBrand)
  }

  func brandTextSmall() -> some View {
    self
      .font(.caption)
      .fontWeight(.bold)
      .foregroundStyle(LinearGradient.beHypeBrand)
  }

  /// Input label text
  func inputLabel() -> some View {
    self
      .font(.subheadline)
      .fontWeight(.medium)
      .foregroundColor(.secondaryText)
  }

  /// Button text
  func buttonText() -> some View {
    self
      .font(.headline)
      .fontWeight(.semibold)
      .foregroundColor(.white)
  }

  /// Small button text
  func smallButtonText() -> some View {
    self
      .font(.subheadline)
      .fontWeight(.medium)
      .foregroundColor(.white)
  }
}

// MARK: - Status Types

enum StatusType {
  case success, pending, failed, confirmed, cancelled

  var color: Color {
    switch self {
    case .success, .confirmed:
      return .bullishGreen
    case .pending:
      return .pendingBlue
    case .failed, .cancelled:
      return .bearishRed
    }
  }

  var displayText: String {
    switch self {
    case .success:
      return "Success"
    case .pending:
      return "Pending"
    case .failed:
      return "Failed"
    case .confirmed:
      return "Confirmed"
    case .cancelled:
      return "Cancelled"
    }
  }
}
