//
//  CMPRow.swift
//  Sandbox
//
//  Created by Stas Kochkin on 18.12.2023.
//

import Foundation
import UIKit
import SwiftUI
import Bidon
import Combine
import StackConsentManager
// import Appodeal

struct CMPRow: View {
    @ObservedObject var vm = CMPViewModel()

    var body: some View {
        Button(action: vm.updateStatusIfNeeded) {
            HStack(spacing: 10) {
                Text("Consent Status")
                    .foregroundColor(.primary)

                Spacer()

                Text(vm.status.stringValue)
                    .foregroundColor(.secondary)

                if vm.isLoading {
                    ProgressView()
                } else {
                    switch vm.status {
                    case .notRequired, .obtained:
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    case .required:
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.red)
                    default:
                        EmptyView()
                    }
                }
            }
        }
        .onAppear(perform: vm.appear)
        .contextMenu {
            Button(action: vm.revoke) {
                Label("Revoke", systemImage: "xmark.circle.fill")
            }

            Button(action: vm.appear) {
                Label("Request", systemImage: "arrow.clockwise.circle.fill")
            }

            Button(action: vm.present) {
                Label("Present", systemImage: "arrow.up.right.circle.fill")
            }
        }
    }
}


final class CMPViewModel: ObservableObject {
    @Published var status: ConsentStatus = .unknown
    @Published var isLoading: Bool = false

    private var cancellables = Set<AnyCancellable>()

    init() {
        ConsentManager
            .shared
            .publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] status in
                self.status = status
            }
            .store(in: &cancellables)
    }

    func appear() {
        guard status == .unknown else { return }

        isLoading = true
        // TODO: Real COPPA value
        let parameters = ConsentUpdateRequestParameters(
            appKey: Constants.Appodeal.appKey,
            mediationSdkName: "Appodeal",
            mediationSdkVersion: Bundle.main.appVersion,
            COPPA: false
        )
        ConsentManager.shared.requestConsentInfoUpdate(
            parameters: parameters
        ) { [weak self] _ in
            self?.isLoading = false
        }
    }

    func updateStatusIfNeeded() {
        guard let vc = UIApplication.shared.bd.topViewcontroller else { return }
        isLoading = true
        ConsentManager.shared.loadAndPresentIfNeeded(rootViewController: vc) { [weak self] _ in
            self?.isLoading = false
        }
    }

    func revoke() {
        ConsentManager.shared.revoke()
    }

    func present() {
        isLoading = true
        ConsentManager.shared.load { [weak self] dialog, _ in
            defer { self?.isLoading = false }
            guard let vc = UIApplication.shared.bd.topViewcontroller, let dialog = dialog else { return }
            dialog.present(rootViewController: vc) { _ in }
        }
    }
}


fileprivate extension ConsentStatus {
    var stringValue: String {
        switch self {
        case .unknown: return "Unknown"
        case .obtained: return "Obtained"
        case .required: return "Required"
        case .notRequired: return "Not required"
        @unknown default: return "unknown"
        }
    }
}
