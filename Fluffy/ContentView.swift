//
//  ContentView.swift
//  Fluffy
//
//  Created by Egor Matveev on 23.04.2026.
//

import Observation
import SwiftUI

struct ContentView: View {
    @State private var coordinator = AppCoordinator()

    var body: some View {
        @Bindable var coordinator = coordinator

        switch coordinator.root {
        case .home:
            coordinator.rootView()
        case .welcome, .auth:
            NavigationStack(path: $coordinator.path) {
                coordinator.rootView()
                    .navigationDestination(for: AppRoute.self) { route in
                        coordinator.destination(for: route)
                    }
            }
        }
    }
}

#Preview {
    ContentView()
}
