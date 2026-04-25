//
//  PawBackgroundView.swift
//  Fluffy
//
//  Created by Egor Matveev on 23.04.2026.
//

import SwiftUI

struct PawBackgroundView: View {
    var body: some View {
        Color.clear
            .background {
                Image(decorative: "WelcomeBackground")
                    .resizable()
                    .scaledToFill()
            }
            .ignoresSafeArea()
    }
}
