//
//  GradientButton.swift
//  Fluffy
//
//  Created by Egor Matveev on 24.04.2026.
//

import SwiftUI

/// Полноширинная кнопка с горизонтальным градиентом и анимацией нажатия.
struct GradientButton: View {

    let title: String
    let gradient: LinearGradient
    let action: () -> Void

    init(
        title: String,
        gradient: LinearGradient = GradientButton.defaultGradient,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.gradient = gradient
        self.action = action
    }

    static let defaultGradient = LinearGradient(
        colors: [Color(hue: 0.75, saturation: 0.85, brightness: 0.90),
                 Color(hue: 0.92, saturation: 0.80, brightness: 0.95)],
        startPoint: .leading,
        endPoint: .trailing
    )

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: GradientButtonLayout.fontSize, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: GradientButtonLayout.height)
                .background(gradient)
                .clipShape(Capsule())
        }
        .buttonStyle(ScaleButtonStyle())
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

private enum GradientButtonLayout {
    static let height: CGFloat = 56
    static let fontSize: CGFloat = 17
}

#Preview {
    GradientButton(title: "Sign In") {}
        .padding()
}
