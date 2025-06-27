//
//  PermissionView.swift
//  Sandbox
//
//  Created by Bidon Team on 05.09.2022.
//

import Foundation
import SwiftUI
import Combine


struct PermissionView: View {
    struct Model: Identifiable {
        var id: String { permission.name }
        var permission: Permission
    }


    @ObservedObject var vm: PermissionViewModel

    init(_ model: Model) {
        self.vm = PermissionViewModel(model.permission)
    }

    var body: some View {
        Button(action: vm.request) {
            HStack {
                Text(vm.name)
                    .foregroundColor(.primary)

                Spacer()

                if vm.isRequesting {
                    ProgressView()
                } else {
                    switch vm.state {
                    case .notDetermined:
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    case .accepted:
                        Image(systemName: "checkmark")
                            .foregroundColor(.accentColor)
                    case .denied:
                        Image(systemName: "exclamationmark.circle")
                            .foregroundColor(.red)
                    }
                }
            }
        }
    }
}


final class PermissionViewModel: ObservableObject {
    @Published var state: PermissionState
    @Published var isRequesting: Bool = false
    @Published var name: String

    private let permission: Permission

    private var cancellables = Set<AnyCancellable>()

    init(_ permission: Permission) {
        self.permission = permission
        self.state = permission.state
        self.name = permission.name
    }

    func request() {
        withAnimation { [unowned self] in
            self.isRequesting = true
        }

        permission
            .requestPublisher()
            .receive(on: DispatchQueue.main)
            .sink {
                withAnimation { [unowned self] in
                    self.state = self.permission.state
                    self.isRequesting = false
                }
            }
            .store(in: &cancellables)
    }
}
