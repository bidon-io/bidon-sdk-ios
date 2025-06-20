//
//  LogLevelView.swift
//  Sandbox
//
//  Created by Bidon Team on 14.02.2023.
//

import Foundation
import SwiftUI


struct LogLevelView: View {
    @Binding var logLevel: LogLevel

    var body: some View {
        NavigationLink(
            destination: {
                SelectLogLevelView(logLevel: $logLevel)
            },
            label: {
                HStack {
                    Text("Log Level")
                        .foregroundColor(.primary)
                    Spacer()
                    Text(logLevel.rawValue.capitalized)
                        .foregroundColor(.secondary)
                }
            }
        )
    }
}


struct SelectLogLevelView: View {
    @Binding var logLevel: LogLevel

    var body: some View {
        List {
            ForEach(LogLevel.allCases, id: \.rawValue) { level in
                Button(action: {
                    withAnimation {
                        logLevel = level
                    }
                }
                ) {
                    HStack {
                        Text(level.rawValue.capitalized)
                            .foregroundColor(.primary)

                        Spacer()

                        if level == logLevel {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)

                        }
                    }
                }
            }
        }
        .navigationTitle("Log Level")
    }
}
