//
//  LogView.swift
//  Asspp
//
//  Created on 2026/2/20.
//

import SwiftUI

struct LogView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var messages: [String] = []
    @State private var unlocked = false

    private func fill() {
        messages = LogManager.shared.getMessages()
    }

    var body: some View {
        ZStack {
            if unlocked {
                List {
                    ForEach(Array(messages.enumerated()), id: \.offset) { _, line in
                        Text(line)
                            .font(.system(.footnote, design: .monospaced))
                            .lineLimit(nil)
                            .textSelection(.enabled)
                    }
                }
                .transition(.opacity)
                .formStyle(.grouped)
                .listStyle(.plain)
                .toolbar {
                    ToolbarItem(placement: .automatic) {
                        Button(action: { fill() }) {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
            } else {
                VStack(spacing: 24) {
                    Spacer()
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.yellow)
                    Text("Sensitive Content")
                        .font(.system(.title2, design: .rounded, weight: .semibold))
                    Text("Logs may contain sensitive account information. Do not screenshot or share them to avoid leaking your credentials.")
                        .font(.system(.callout, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    Button(role: .destructive) {
                        unlocked = true
                        fill()
                    } label: {
                        Text("Show Logs")
                            .font(.system(.body, design: .rounded, weight: .semibold))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    Spacer()
                }
                .transition(.opacity)
            }
        }
        .animation(.spring, value: unlocked)
        .navigationTitle("Logs")
    }
}
