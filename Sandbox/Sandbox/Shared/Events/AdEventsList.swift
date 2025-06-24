//
//  AdEventsList.swift
//  Sandbox
//
//  Created by Bidon Team on 26.08.2022.
//

import Foundation
import SwiftUI


struct AdEventsList: View {
    var events: [AdEventModel]

    var body: some View {
        ZStack {
            Color(UIColor.secondarySystemBackground).edgesIgnoringSafeArea(.all)

            ScrollView {
                LazyVStack(spacing: 5) {
                    ForEach(events) { model in
                        AdEventView(model: model)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 5).fill(Color(UIColor.systemBackground)))
                            .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Ad Events")
        }

    }
}
