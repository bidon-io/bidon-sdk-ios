//
//  HostView.swift
//  Sandbox
//
//  Created by Bidon Team on 05.09.2022.
//

import Foundation
import SwiftUI


struct HostView: View {
    struct Model: Identifiable, Codable, Equatable {
        var id: String { name }

        var name: String
        var baseURL: String
        var user: String?
        var password: String?
    }

    @Binding var hosts: [Model]
    @Binding var selected: Model

    var body: some View {
        NavigationLink(
            destination: {
                SelectHostView(hosts: $hosts, selected: $selected)
            },
            label: {
                VStack(alignment: .leading) {
                    Text(selected.name)
                        .foregroundColor(.primary)
                    Text(selected.baseURL)
                        .foregroundColor(.secondary)
                }
            }
        )
    }
}


struct SelectHostView: View {
    @Binding var hosts: [HostView.Model]
    @Binding var selected: HostView.Model

    @State var isScannerPresented: Bool = false

    var body: some View {
        List {
            ForEach(hosts) { host in
                Button(action: {
                    withAnimation {
                        selected = host
                    }
                }) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(host.name)
                                .foregroundColor(.primary)
                            Text(host.baseURL)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        if selected == host {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)

                        }
                    }
                }
            }
        }
        .sheet(isPresented: $isScannerPresented) {
            CreateHostView(
                isPresented: $isScannerPresented,
                hosts: $hosts,
                selected: $selected
            )
        }
        .navigationTitle("Base URL")
        .toolbar {
            ToolbarItem(
                placement: .navigationBarTrailing
            ) {
                Button(action: {
                    withAnimation {
                        isScannerPresented = true
                    }
                }) {
                    Image(systemName: "plus")
                }
            }
        }
    }
}


struct CreateHostView: View {
    @Binding var isPresented: Bool
    @Binding var hosts: [HostView.Model]
    @Binding var selected: HostView.Model

    @State private var text: String = ""

    private var model: HostView.Model {
        HostView.Model(
            name: URL(string: text).flatMap { $0.host }.map { $0.prefix(5) + "..." } ?? "Custom",
            baseURL: text
        )
    }

    var body: some View {
        ZStack {
            QRCodeScannerView(
                codeTypes: [.qr],
                completion: handleScannerResult
            )

#if !targetEnvironment(simulator)
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.accentColor, lineWidth: 1.5)
                .padding(64)
                .aspectRatio(1, contentMode: .fit)
#endif
            VStack {
                Spacer()

                VStack {
                    Text("Scan ") +
                    Text("QR Code").bold() +
                    Text(" with server URL or enter it ") +
                    Text("manually.").bold()

                    TextField(model.name, text: $text)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.URL)
                        .autocorrectionDisabled(true)
                        .autocapitalization(.none)
                        .padding()


                    Button(action: {
                        withAnimation {
                            hosts.append(model)
                            selected = model
                            isPresented = false
                        }
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.accentColor)
                            Text("Save")
                                .bold()
                                .foregroundColor(.white)
                        }
                        .frame(height: 44)
                    }
                    .padding(.horizontal)
                    .disabled(text.isEmpty)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.primary).opacity(0.1))
                .padding()
            }
        }
    }

    private func handleScannerResult(_ result: Result<String, QRCodeScannerView.ScanError>) {
        switch result {
        case .success(let url):
            guard !url.isEmpty else { return }
            withAnimation {
                text = url
            }
        case.failure:
            break
        }
    }
}
