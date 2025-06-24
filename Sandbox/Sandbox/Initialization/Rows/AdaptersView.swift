//
//  AdaptersView.swift
//  Sandbox
//
//  Created by Bidon Team on 14.02.2023.
//

import Foundation
import SwiftUI
import Bidon


struct AdaptersView: View {
    @Binding var adapters: [Bidon.Adapter]

    var body: some View {
        ForEach($adapters, id: \.demandId) { $adapter in
            Button(action: {
                withAnimation {
                    adapter.isEnabled = true
                }
            }) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Bidon \(adapter.name) Adapter")
                            .foregroundColor(adapter.isEnabled ? .secondary : .primary)
                        Text("SDK version \(adapter.sdkVersion)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    if adapter.isEnabled {
                        Image(systemName: "checkmark")
                            .foregroundColor(.accentColor)
                    }
                }
            }
            .disabled(adapter.isEnabled)
        }
    }
}


extension Bidon.Adapter {
    var isEnabled: Bool {
        get { BidonSdk.registeredAdapters().contains { $0.demandId == self.demandId } }
        set {
            guard newValue else { return }
            BidonSdk.registerAdapter(adapter: self)
        }
    }
}
