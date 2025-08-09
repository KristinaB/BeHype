//
//  Cards.swift
//  BeHype
//
//  Reusable card components with dark theme and glass effects 🌟✨
//

import SwiftUI

// MARK: - App Card

struct AppCard<Content: View>: View {
  let content: Content

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  var body: some View {
    content
      .padding(20)
      .background(
        ZStack {
          // Main card background
          RoundedRectangle(cornerRadius: 16)
            .fill(Color.cardBackground)

          // Glass effect overlay
          RoundedRectangle(cornerRadius: 16)
            .fill(LinearGradient.cardBackground)

          // Subtle border
          RoundedRectangle(cornerRadius: 16)
            .strokeBorder(
              LinearGradient(
                colors: [
                  Color.borderLight.opacity(0.3),
                  Color.borderGray.opacity(0.1),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              ),
              lineWidth: 1
            )
        }
      )
  }
}

// MARK: - Info Card

struct InfoCard: View {
  let title: String
  let items: [(String, String, Color?)]

  init(title: String, items: [(String, String, Color?)] = []) {
    self.title = title
    self.items = items
  }

  var body: some View {
    AppCard {
      VStack(alignment: .leading, spacing: 16) {
        Text(title)
          .cardTitle()

        VStack(spacing: 12) {
          ForEach(Array(items.enumerated()), id: \.offset) { _, item in
            InfoRow(title: item.0, value: item.1, color: item.2)
          }
        }
      }
    }
  }
}

// MARK: - Info Row

struct InfoRow: View {
  let title: String
  let value: String
  let color: Color?

  init(title: String, value: String, color: Color? = nil) {
    self.title = title
    self.value = value
    self.color = color
  }

  var body: some View {
    HStack {
      Text(title)
        .secondaryText()

      Spacer()

      Text(value)
        .bodyText()
        .fontWeight(.medium)
        .foregroundColor(color ?? .primaryText)
    }
  }
}

// MARK: - Input Card

struct InputCard<Content: View>: View {
  let title: String
  let content: Content

  init(title: String, @ViewBuilder content: () -> Content) {
    self.title = title
    self.content = content()
  }

  var body: some View {
    AppCard {
      VStack(alignment: .leading, spacing: 16) {
        Text(title)
          .cardTitle()
          .foregroundColor(.secondaryText)

        content
      }
    }
  }
}

// MARK: - Market Card

struct MarketCard: View {
  let symbol: String
  let price: String
  let change: String
  let isPositive: Bool

  var body: some View {
    AppCard {
      HStack {
        VStack(alignment: .leading, spacing: 8) {
          Text(symbol)
            .cardTitle()

          Text(price)
            .priceText()
        }

        Spacer()

        VStack(alignment: .trailing, spacing: 8) {
          if isPositive {
            Text(change)
              .brandTextSmall()
          } else {
            Text(change)
              .priceText(color: .bearishRed)
              .fontWeight(.semibold)
          }

          HStack(spacing: 4) {
            Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
              .font(.caption)
              .foregroundColor(isPositive ? .bullishGreen : .bearishRed)
          }
        }
      }
    }
  }
}

// MARK: - Portfolio Card

struct PortfolioCard: View {
  let title: String
  let balance: String
  let value: String
  let change: String?
  let isPositive: Bool?

  var body: some View {
    AppCard {
      VStack(alignment: .leading, spacing: 12) {
        Text(title)
          .secondaryText()

        HStack(alignment: .bottom, spacing: 8) {
          VStack(alignment: .leading, spacing: 4) {
            Text(balance)
              .sectionTitle()

            Text(value)
              .secondaryText()
          }

          Spacer()

          if let change = change, let isPositive = isPositive {
            Text(change)
              .captionText()
              .foregroundColor(isPositive ? .bullishGreen : .bearishRed)
              .padding(.horizontal, 8)
              .padding(.vertical, 4)
              .background(
                Capsule()
                  .fill((isPositive ? Color.bullishGreen : Color.bearishRed).opacity(0.2))
              )
          }
        }
      }
    }
  }
}

// MARK: - Action Card

struct ActionCard: View {
  let icon: String
  let title: String
  let subtitle: String
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      AppCard {
        HStack(spacing: 16) {
          ZStack {
            Circle()
              .fill(LinearGradient.primaryButton)
              .frame(width: 50, height: 50)

            Image(systemName: icon)
              .font(.title2)
              .foregroundColor(.white)
          }

          VStack(alignment: .leading, spacing: 4) {
            Text(title)
              .cardTitle()

            Text(subtitle)
              .captionText()
          }

          Spacer()

          Image(systemName: "chevron.right")
            .font(.headline)
            .foregroundColor(.tertiaryText)
        }
      }
    }
    .buttonStyle(PlainButtonStyle())
  }
}
