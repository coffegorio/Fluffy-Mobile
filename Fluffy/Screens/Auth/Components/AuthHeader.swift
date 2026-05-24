//
//  AuthHeader.swift
//  Fluffy
//
//  Created by Egor Matveev on 24.04.2026.
//

import SwiftUI

struct AuthHeader: View {
    @ScaledMetric private var iconSize = AuthLayout.iconSize
    @ScaledMetric private var titleSize = AuthLayout.titleSize
    @ScaledMetric private var subtitleSize = AuthLayout.subtitleSize

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(systemName: "pawprint.fill")
                .font(.system(size: iconSize, weight: .bold))
                .foregroundStyle(.accent)
                .accessibilityHidden(true)
                .padding(.top, AuthLayout.iconTopPadding)
                .padding(.bottom, AuthLayout.iconBottomPadding)

            Text("auth_title")
                .font(.system(size: titleSize, weight: .heavy))
                .foregroundStyle(.primary)

            Text("auth_subtitle")
                .font(.system(size: subtitleSize, weight: .regular))
                .foregroundStyle(.secondary)
                .padding(.top, AuthLayout.subtitleTopPadding)
                .padding(.bottom, AuthLayout.subtitleBottomPadding)
        }
    }
}
