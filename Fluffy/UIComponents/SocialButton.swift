//
//  SocialButton.swift
//  Fluffy
//
//  Created by Egor Matveev on 24.04.2026.
//

import SwiftUI

/// Кнопка входа через соцсеть с иконкой и подписью. Используется в паре (Google / Facebook).
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
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: SocialButtonLayout.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: SocialButtonLayout.cornerRadius)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Social Icon

enum SocialIcon {
    case google
    case facebook

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
        case .facebook:
            Text("f")
                .font(.system(size: SocialButtonLayout.facebookIconSize, weight: .bold, design: .rounded))
                .foregroundStyle(.blue)
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
    static let facebookIconSize: CGFloat = 24
    static let iconSpacing: CGFloat = 10
    static let fontSize: CGFloat = 15
    static let cornerRadius: CGFloat = 12
}

#Preview {
    HStack(spacing: 12) {
        SocialButton(title: "Google", icon: .google) {}
        SocialButton(title: "Facebook", icon: .facebook) {}
    }
    .padding()
}
