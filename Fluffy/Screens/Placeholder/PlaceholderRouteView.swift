//
//  PlaceholderRouteView.swift
//  Fluffy
//
//  Created by Egor Matveev on 25.04.2026.
//

import SwiftUI

struct PlaceholderRouteView: View {
    let title: String

    var body: some View {
        Text(title)
            .navigationTitle(title)
    }
}
