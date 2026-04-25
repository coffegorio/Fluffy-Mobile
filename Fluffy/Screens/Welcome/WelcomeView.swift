//
//  WelcomeView.swift
//  Fluffy
//
//  Created by Egor Matveev on 23.04.2026.
//

import SwiftUI

struct WelcomeView: View {
    var onContinue: () -> Void = {}

    @ScaledMetric private var titleSize = WelcomeLayout.titleSize
    @ScaledMetric private var subtitleSize = WelcomeLayout.subtitleSize
    
    var body: some View {
        ZStack {
            WelcomeBackgroundView()
        
            VStack {
                Spacer()
                
                ZStack {
                    WelcomeWaveShape()
                        .fill(Color.white)
                        .ignoresSafeArea(edges: .bottom)
                    
                    VStack(alignment: .leading, spacing: WelcomeLayout.contentSpacing) {
                        Text("welcome_title")
                            .font(.system(size: titleSize, weight: .heavy))
                            .foregroundStyle(.black)
                        
                        Text("welcome_subtitle")
                            .font(.system(size: subtitleSize, weight: .medium))
                            .foregroundStyle(.secondary)
                            .lineSpacing(WelcomeLayout.subtitleLineSpacing)
                        
                        Spacer()
                    
                        ContinueButton(action: onContinue)
                    }
                    .padding(.horizontal, WelcomeLayout.horizontalPadding)
                    .padding(.top, WelcomeLayout.contentTopPadding)
                    .padding(.bottom, WelcomeLayout.contentBottomPadding)
                }
                .frame(height: WelcomeLayout.bottomPanelHeight)
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }
}



#Preview {
    WelcomeView()
}
