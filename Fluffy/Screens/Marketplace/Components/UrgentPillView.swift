//
//  UrgentPillView.swift
//  Fluffy
//

import SwiftUI

struct UrgentPillView: View {
    var body: some View {
        Text("listing_urgent")
            .font(.system(size: 10, weight: .heavy))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(AppTheme.danger, in: Capsule())
    }
}
