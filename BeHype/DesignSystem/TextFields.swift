//
//  TextFields.swift
//  BeHype
//
//  Reusable text field components with dark theme styling 📝✨
//

import SwiftUI

// MARK: - App Text Field

struct AppTextField: View {
  let title: String
  let placeholder: String
  @Binding var text: String
  let keyboardType: UIKeyboardType
  let isSecure: Bool

  init(
    _ title: String,
    placeholder: String = "",
    text: Binding<String>,
    keyboardType: UIKeyboardType = .default,
    isSecure: Bool = false
  ) {
    self.title = title
    self.placeholder = placeholder
    self._text = text
    self.keyboardType = keyboardType
    self.isSecure = isSecure
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title)
        .inputLabel()

      Group {
        if isSecure {
          SecureField(placeholder, text: $text)
        } else {
          TextField(placeholder, text: $text)
        }
      }
      .font(.body)
      .foregroundColor(.primaryText)
      .padding()
      .background(
        RoundedRectangle(cornerRadius: 12)
          .fill(Color.inputBackground)
          .overlay(
            RoundedRectangle(cornerRadius: 12)
              .strokeBorder(Color.borderGray.opacity(0.3), lineWidth: 1)
          )
      )
      .keyboardType(keyboardType)
    }
  }
}

// MARK: - Amount Text Field

struct AmountTextField: View {
  let title: String
  let symbol: String
  @Binding var amount: String
  let balance: String?
  let onMaxTapped: (() -> Void)?

  init(
    _ title: String,
    symbol: String,
    amount: Binding<String>,
    balance: String? = nil,
    onMaxTapped: (() -> Void)? = nil
  ) {
    self.title = title
    self.symbol = symbol
    self._amount = amount
    self.balance = balance
    self.onMaxTapped = onMaxTapped
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text(title)
          .inputLabel()

        Spacer()

        if let balance = balance {
          Text("Balance: \(balance)")
            .captionText()
        }
      }

      HStack {
        TextField("0.00", text: $amount)
          .font(.title2)
          .fontWeight(.semibold)
          .foregroundColor(.primaryText)
          .keyboardType(.decimalPad)

        VStack {
          Text(symbol)
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.secondaryText)

          if onMaxTapped != nil {
            OutlineButton("MAX", size: .small) {
              onMaxTapped?()
            }
          }
        }
      }
      .padding()
      .background(
        RoundedRectangle(cornerRadius: 12)
          .fill(Color.inputBackground)
          .overlay(
            RoundedRectangle(cornerRadius: 12)
              .strokeBorder(Color.borderGray.opacity(0.3), lineWidth: 1)
          )
      )
    }
  }
}

// MARK: - Price Text Field

struct PriceTextField: View {
  let title: String
  @Binding var price: String
  let marketPrice: String?
  let onMarketTapped: (() -> Void)?

  init(
    _ title: String,
    price: Binding<String>,
    marketPrice: String? = nil,
    onMarketTapped: (() -> Void)? = nil
  ) {
    self.title = title
    self._price = price
    self.marketPrice = marketPrice
    self.onMarketTapped = onMarketTapped
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text(title)
          .inputLabel()

        Spacer()

        if let marketPrice = marketPrice {
          Text("Market: $\(marketPrice)")
            .captionText()
        }
      }

      HStack {
        Text("$")
          .font(.title2)
          .fontWeight(.medium)
          .foregroundColor(.secondaryText)

        TextField("0.00", text: $price)
          .font(.title2)
          .fontWeight(.semibold)
          .foregroundColor(.primaryText)
          .keyboardType(.decimalPad)

        if onMarketTapped != nil {
          OutlineButton("MARKET", size: .small) {
            onMarketTapped?()
          }
        }
      }
      .padding()
      .background(
        RoundedRectangle(cornerRadius: 12)
          .fill(Color.inputBackground)
          .overlay(
            RoundedRectangle(cornerRadius: 12)
              .strokeBorder(Color.borderGray.opacity(0.3), lineWidth: 1)
          )
      )
    }
  }
}

// MARK: - Search Text Field

struct SearchTextField: View {
  @Binding var searchText: String
  let placeholder: String

  init(_ placeholder: String = "Search...", text: Binding<String>) {
    self.placeholder = placeholder
    self._searchText = text
  }

  var body: some View {
    HStack {
      Image(systemName: "magnifyingglass")
        .foregroundColor(.tertiaryText)

      TextField(placeholder, text: $searchText)
        .font(.body)
        .foregroundColor(.primaryText)

      if !searchText.isEmpty {
        Button(action: { searchText = "" }) {
          Image(systemName: "xmark.circle.fill")
            .foregroundColor(.tertiaryText)
        }
      }
    }
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(Color.inputBackground)
        .overlay(
          RoundedRectangle(cornerRadius: 12)
            .strokeBorder(Color.borderGray.opacity(0.3), lineWidth: 1)
        )
    )
  }
}
