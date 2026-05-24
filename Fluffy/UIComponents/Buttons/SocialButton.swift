//
//  SocialButton.swift
//  Fluffy
//
//  Created by Egor Matveev on 24.04.2026.
//

import SwiftUI

/// Кнопка входа через соцсеть с иконкой и подписью.
struct SocialButton: View {

    let title: String
    let icon: SocialIcon
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: SocialButtonLayout.iconSpacing) {
                icon.view
                    .frame(width: SocialButtonLayout.iconSize, height: SocialButtonLayout.iconSize)

                Text(title)
                    .font(.system(size: SocialButtonLayout.fontSize, weight: .medium))
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: SocialButtonLayout.height)
            .background(Color(.systemBackground).opacity(0.55))
            .fluffyGlass(cornerRadius: SocialButtonLayout.cornerRadius, tint: .white.opacity(0.14), isInteractive: true)
            .clipShape(RoundedRectangle(cornerRadius: SocialButtonLayout.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: SocialButtonLayout.cornerRadius)
                    .stroke(.white.opacity(0.42), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Social Icon

enum SocialIcon {
    case google
    case apple

    @ViewBuilder
    var view: some View {
        switch self {
        case .google:
            Text("G")
                .font(.system(size: SocialButtonLayout.googleIconSize, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .red, .yellow, .green],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        case .apple:
            Image(systemName: "apple.logo")
                .font(.system(size: SocialButtonLayout.appleIconSize, weight: .semibold))
                .foregroundStyle(.primary)
        }
    }
}

// MARK: - Scale press animation

private struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

private enum SocialButtonLayout {
    static let height: CGFloat = 52
    static let iconSize: CGFloat = 22
    static let googleIconSize: CGFloat = 20
    static let appleIconSize: CGFloat = 20
    static let iconSpacing: CGFloat = 10
    static let fontSize: CGFloat = 15
    static let cornerRadius: CGFloat = 12
}

#Preview {
    HStack(spacing: 12) {
        SocialButton(title: "Google", icon: .google) {}
        SocialButton(title: "Apple", icon: .apple) {}
    }
    .padding()
}
