//
//  WelcomeViewModel.swift
//  Fluffy
//
//  Created by Egor Matveev on 25.04.2026.
//

import Observation

protocol WelcomeCoordinating: AnyObject {
    func showAuth()
}

@Observable
final class WelcomeViewModel {
    private weak var coordinator: WelcomeCoordinating?

    init(coordinator: WelcomeCoordinating?) {
        self.coordinator = coordinator
    }

    func continueTapped() {
        coordinator?.showAuth()
    }
}
