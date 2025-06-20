//
//  ActivityPlaceholder.swift
//  Sandbox
//
//  Created by Bidon Team on 12.04.2023.
//

import Foundation
import SwiftUI


struct ActivityPlaceholder: View {
    var body: some View {
        ZStack {
            ProgressView()
                .progressViewStyle(.circular)
        }
    }
}


struct VisualEffectView: UIViewRepresentable {
    var effect: UIVisualEffect?

    func makeUIView(
        context: UIViewRepresentableContext<Self>
    ) -> UIVisualEffectView {
        UIVisualEffectView()
    }

    func updateUIView(
        _ uiView: UIVisualEffectView,
        context: UIViewRepresentableContext<Self>
    ) {
        uiView.effect = effect
    }
}
