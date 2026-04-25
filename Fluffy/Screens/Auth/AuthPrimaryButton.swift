//
//  AuthPrimaryButton.swift
//  Fluffy
//
//  Created by Egor Matveev on 24.04.2026.
//

import SwiftUI

struct AuthPrimaryButton: View {
    let action: () -> Void

    @ScaledMetric private var height = AuthLayout.primaryButtonHeight
    @ScaledMetric private var fontSize = AuthLayout.primaryButtonFontSize

    var body: some View {
        Button(action: action) {
            Text("auth_sign_in_button")
                .font(.system(size: fontSize, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .background(.accent, in: Capsule())
        }
    }
}
