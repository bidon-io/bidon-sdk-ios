//
//  SelectMediationView.swift
//  Sandbox
//
//  Created by Bidon Team on 16.02.2023.
//

import Foundation
import SwiftUI


struct SelectMediationView: View {
    @Binding var mediation: Mediation

    var body: some View {
        ForEach(Mediation.allCases, id: \.rawValue) { mediation in
            Button(action: {
                withAnimation {
                    self.mediation = mediation
                }
            }) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(mediation.rawValue.capitalized)
                            .foregroundColor(.primary)
                    }

                    Spacer()

                    if self.mediation == mediation {
                        Image(systemName: "checkmark")
                            .foregroundColor(.accentColor)
                    }
                }
            }
        }
    }
}
