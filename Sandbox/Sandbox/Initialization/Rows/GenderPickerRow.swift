//
//  GenderPickerRow.swift
//  Sandbox
//
//  Created by Stas Kochkin on 18.12.2023.
//

import Foundation
import SwiftUI


struct GenderPickerRow: View {
    @Binding var gender: Gender
    
    var body: some View {
        ForEach(Gender.allCases, id: \.rawValue) { option in
            Button(action: {
                withAnimation {
                    gender = option
                }
            }
            ) {
                HStack {
                    Text(option.rawValue.capitalized)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if option == gender {
                        Image(systemName: "checkmark")
                            .foregroundColor(.accentColor)
                        
                    }
                }
            }
        }
    }
}

