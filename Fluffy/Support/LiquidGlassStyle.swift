//
//  LiquidGlassStyle.swift
//  Fluffy
//

import SwiftUI

extension View {
    @ViewBuilder
    func fluffyGlass(
        cornerRadius: CGFloat = AppTheme.cardRadius,
        tint: Color = .white.opacity(0.18),
        isInteractive: Bool = false
    ) -> some View {
        if #available(iOS 26.0, *) {
            if isInteractive {
                self.glassEffect(
                    .regular.tint(tint).interactive(),
                    in: .rect(cornerRadius: cornerRadius)
                )
            } else {
                self.glassEffect(
                    .regular.tint(tint),
                    in: .rect(cornerRadius: cornerRadius)
                )
            }
        } else {
            self.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
        }
    }

    @ViewBuilder
    func fluffyProminentGlass(
        cornerRadius: CGFloat = AppTheme.cardRadius,
        tint: Color = AppTheme.accent.opacity(0.18)
    ) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(
                .regular.tint(tint).interactive(),
                in: .rect(cornerRadius: cornerRadius)
            )
        } else {
            self.background(.regularMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
        }
    }
}
