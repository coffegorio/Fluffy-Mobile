//
//  CapsuleActionButton.swift
//  Fluffy
//
//  Created by Egor Matveev on 24.04.2026.
//

import SwiftUI

struct CapsuleActionButton: View {
    let title: LocalizedStringKey
    var systemImage: String?
    var height: CGFloat = CapsuleActionButtonLayout.height
    var fontSize: CGFloat = CapsuleActionButtonLayout.fontSize
    var contentSpacing: CGFloat = CapsuleActionButtonLayout.contentSpacing
    let action: () -> Void

    @ScaledMetric private var scaledHeight: CGFloat
    @ScaledMetric private var scaledFontSize: CGFloat

    init(
        title: LocalizedStringKey,
        systemImage: String? = nil,
        height: CGFloat = CapsuleActionButtonLayout.height,
        fontSize: CGFloat = CapsuleActionButtonLayout.fontSize,
        contentSpacing: CGFloat = CapsuleActionButtonLayout.contentSpacing,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.height = height
        self.fontSize = fontSize
        self.contentSpacing = contentSpacing
        self.action = action
        _scaledHeight = ScaledMetric(wrappedValue: height)
        _scaledFontSize = ScaledMetric(wrappedValue: fontSize)
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: contentSpacing) {
                Text(title)
                    .font(.system(size: scaledFontSize, weight: .bold))

                if let systemImage {
                    Image(systemName: systemImage)
                        .imageScale(.large)
                        .bold()
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: scaledHeight)
            .background(.accent, in: Capsule())
        }
    }
}

private enum CapsuleActionButtonLayout {
    static let height: CGFloat = 56
    static let fontSize: CGFloat = 17
    static let contentSpacing: CGFloat = 8
}
