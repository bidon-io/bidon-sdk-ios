//
//  ContentViewModel.swift
//  Sandbox
//
//  Created by Bidon Team on 05.09.2022.
//

import Foundation
import Combine
import SwiftUI


final class ContentViewModel: ObservableObject {
    @Published var isInitialized: Bool = false
    @Published var initializationViewModel = InitializationViewModel()

    private var cancellables = Set<AnyCancellable>()

    init() {
        subscribe()
    }

    private func subscribe() {
        initializationViewModel
            .$initializationState
            .map { $0 == .initialized }
            .receive(on: DispatchQueue.main)
            .sink { isInitialized in
                withAnimation { [unowned self] in
                    self.isInitialized = isInitialized
                }
            }
            .store(in: &cancellables)
    }
}
