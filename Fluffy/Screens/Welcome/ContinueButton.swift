//
//  ContinueButton.swift
//  Fluffy
//
//  Created by Egor Matveev on 23.04.2026.
//

import SwiftUI

struct ContinueButton: View {
    let action: () -> Void

    @ScaledMetric private var height = WelcomeLayout.continueButtonHeight

    var body: some View {
        Button(action: action) {
            HStack(spacing: WelcomeLayout.continueButtonContentSpacing) {
                Text("welcome_continue_button")
                    .bold()

                Image(systemName: "arrow.right")
                    .imageScale(.large)
                    .bold()
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(.accent, in: Capsule())
        }
    }
}
