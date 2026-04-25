//
//  AuthActions.swift
//  Fluffy
//
//  Created by Egor Matveev on 24.04.2026.
//

import SwiftUI

struct AuthActions: View {
    let onSignIn: () -> Void
    let onSignUp: () -> Void
    let onGoogleSignIn: () -> Void
    let onFacebookSignIn: () -> Void

    @ScaledMetric private var signUpFontSize = AuthLayout.signUpFontSize
    @ScaledMetric private var dividerFontSize = AuthLayout.dividerFontSize

    var body: some View {
        VStack(spacing: AuthLayout.bottomSectionSpacing) {
            CapsuleActionButton(
                title: "auth_sign_in_button",
                height: AuthLayout.primaryButtonHeight,
                fontSize: AuthLayout.primaryButtonFontSize,
                action: onSignIn
            )
            signUpRow
            orDivider
            socialButtons
        }
    }

    private var signUpRow: some View {
        HStack(spacing: AuthLayout.signUpRowSpacing) {
            Text("auth_no_account_prefix")
                .font(.system(size: signUpFontSize))
                .foregroundStyle(.secondary)

            Button(action: onSignUp) {
                Text("auth_sign_up_action")
                    .font(.system(size: signUpFontSize, weight: .semibold))
                    .foregroundStyle(.accent)
            }
        }
    }

    private var orDivider: some View {
        LabeledDivider(
            title: "auth_or_continue_with",
            fontSize: dividerFontSize,
            spacing: AuthLayout.dividerSpacing,
            lineHeight: AuthLayout.dividerHeight
        )
    }

    private var socialButtons: some View {
        HStack(spacing: AuthLayout.socialButtonSpacing) {
            SocialButton(
                title: String(localized: "auth_social_google"),
                icon: .google,
                action: onGoogleSignIn
            )

            SocialButton(
                title: String(localized: "auth_social_facebook"),
                icon: .facebook,
                action: onFacebookSignIn
            )
        }
    }
}
