//
//  AdEventView.swift
//  Sandbox
//
//  Created by Bidon Team on 26.08.2022.
//

import Foundation
import SwiftUI


struct AdEventView: View {
    var model: AdEventModel
    
    static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
    
    var body: some View {
        if #available(iOS 16, *) {
            content
                .contextMenu {
                    Button(action: {
                        UIPasteboard.general.string = model.title + "\n" + model.subtitle
                    }) {
                        Text("Copy event")
                        Image(systemName: "doc.on.doc")
                    }
                } preview: {
                    Text(model.title + "\n" + model.subtitle)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                }
        } else {
            content
        }
    }
    
    var content: some View {
        HStack {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(model.adType.title)
                        .font(.system(size: 14, weight: .black, design: .monospaced))
                        .multilineTextAlignment(.leading)
                        .lineLimit(nil)
                    
                    Image(systemName: model.bage)
                        .foregroundColor(model.color)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                
                Text(model.title)
                    .foregroundColor(.primary)
                
                Text(model.subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            VStack(alignment: .trailing, spacing: 10) {
                Spacer()
                Text(AdEventView.formatter.string(from: model.date))
                    .font(.caption).foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .frame(minHeight: 80)
            }
        }
    }
}
