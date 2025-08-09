//
//  Buttons.swift
//  BeHype
//
//  Reusable button components with dark theme styling 🔘✨
//

import SwiftUI

// MARK: - Primary Button

struct PrimaryButton: View {
  let title: String
  let isLoading: Bool
  let isDisabled: Bool
  let action: () -> Void

  init(
    _ title: String,
    isLoading: Bool = false,
    isDisabled: Bool = false,
    action: @escaping () -> Void
  ) {
    self.title = title
    self.isLoading = isLoading
    self.isDisabled = isDisabled
    self.action = action
  }

  var body: some View {
    Button(action: action) {
      HStack {
        if isLoading {
          ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: .white))
            .scaleEffect(0.8)
        } else {
          Text(title)
            .buttonText()
        }
      }
      .frame(maxWidth: .infinity)
      .frame(height: 50)
      .background(
        RoundedRectangle(cornerRadius: 12)
          .fill(
            isDisabled
              ? AnyShapeStyle(Color.borderGray) : AnyShapeStyle(LinearGradient.primaryButton)
          )
      )
    }
    .disabled(isDisabled || isLoading)
    .opacity(isDisabled ? 0.6 : 1.0)
  }
}

// MARK: - Secondary Button

struct SecondaryButton: View {
  let title: String
  let isLoading: Bool
  let isDisabled: Bool
  let action: () -> Void

  init(
    _ title: String,
    isLoading: Bool = false,
    isDisabled: Bool = false,
    action: @escaping () -> Void
  ) {
    self.title = title
    self.isLoading = isLoading
    self.isDisabled = isDisabled
    self.action = action
  }

  var body: some View {
    Button(action: action) {
      HStack {
        if isLoading {
          ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: .secondaryText))
            .scaleEffect(0.8)
        } else {
          Text(title)
            .smallButtonText()
            .foregroundColor(.secondaryText)
        }
      }
      .frame(maxWidth: .infinity)
      .frame(height: 44)
      .background(
        RoundedRectangle(cornerRadius: 12)
          .fill(Color.inputBackground)
          .overlay(
            RoundedRectangle(cornerRadius: 12)
              .strokeBorder(Color.borderGray, lineWidth: 1)
          )
      )
    }
    .disabled(isDisabled || isLoading)
    .opacity(isDisabled ? 0.6 : 1.0)
  }
}

// MARK: - Small Button

struct SmallButton: View {
  let title: String
  let icon: String?
  let action: () -> Void

  init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
    self.title = title
    self.icon = icon
    self.action = action
  }

  var body: some View {
    Button(action: action) {
      HStack(spacing: 6) {
        if let icon = icon {
          Image(systemName: icon)
            .font(.caption)
        }

        Text(title)
          .font(.caption)
          .fontWeight(.medium)
      }
      .foregroundColor(.white)
      .padding(.horizontal, 12)
      .padding(.vertical, 6)
      .background(
        Capsule()
          .fill(LinearGradient.primaryButton)
      )
    }
  }
}

// MARK: - Icon Button

struct IconButton: View {
  let icon: String
  let size: CGFloat
  let action: () -> Void

  init(icon: String, size: CGFloat = 24, action: @escaping () -> Void) {
    self.icon = icon
    self.size = size
    self.action = action
  }

  var body: some View {
    Button(action: action) {
      Image(systemName: icon)
        .font(.system(size: size))
        .foregroundColor(.secondaryText)
        .frame(width: 44, height: 44)
        .background(
          Circle()
            .fill(Color.inputBackground)
            .overlay(
              Circle()
                .strokeBorder(Color.borderGray.opacity(0.5), lineWidth: 1)
            )
        )
    }
  }
}

// MARK: - Tab Button

struct TabButton: View {
  let title: String
  let icon: String
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      VStack(spacing: 4) {
        Image(systemName: icon)
          .font(.system(size: 18, weight: .medium))

        Text(title)
          .font(.caption)
          .fontWeight(.medium)
      }
      .foregroundColor(isSelected ? .primaryText : .tertiaryText)
      .frame(maxWidth: .infinity)
      .padding(.vertical, 8)
      .background(
        RoundedRectangle(cornerRadius: 12)
          .fill(
            isSelected
              ? AnyShapeStyle(LinearGradient.cardBackground)
              : AnyShapeStyle(Color.clear)
          )
      )
    }
    .buttonStyle(PlainButtonStyle())
  }
}

// MARK: - Filter Button

struct FilterButton: View {
  let title: String
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Text(title)
        .font(.caption)
        .fontWeight(.medium)
        .foregroundColor(isSelected ? .primaryText : .secondaryText)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
          Capsule()
            .fill(
              isSelected
                ? AnyShapeStyle(
                  LinearGradient(
                    colors: [
                      Color.white.opacity(0.3),
                      Color.white.opacity(0.15),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                  ))
                : AnyShapeStyle(Color.clear)
            )
            .overlay(
              Capsule()
                .strokeBorder(
                  Color.borderGray.opacity(0.3),
                  lineWidth: 1
                )
            )
        )
    }
    .buttonStyle(PlainButtonStyle())
  }
}
