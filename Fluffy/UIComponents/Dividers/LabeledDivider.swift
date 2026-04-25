//
//  LabeledDivider.swift
//  Fluffy
//
//  Created by Egor Matveev on 24.04.2026.
//

import SwiftUI

struct LabeledDivider: View {
    let title: LocalizedStringKey
    var fontSize: CGFloat = LabeledDividerLayout.fontSize
    var spacing: CGFloat = LabeledDividerLayout.spacing
    var lineHeight: CGFloat = LabeledDividerLayout.lineHeight

    var body: some View {
        HStack(spacing: spacing) {
            line

            Text(title)
                .font(.system(size: fontSize))
                .foregroundStyle(.secondary)

            line
        }
    }

    private var line: some View {
        Rectangle()
            .fill(Color(.systemGray4))
            .frame(height: lineHeight)
    }
}

private enum LabeledDividerLayout {
    static let fontSize: CGFloat = 14
    static let spacing: CGFloat = 12
    static let lineHeight: CGFloat = 1
}
