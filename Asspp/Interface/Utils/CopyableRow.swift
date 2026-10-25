//
//  CopyableRow.swift
//  Asspp
//

import SwiftUI

struct CopyableRow: View {
    let label: String
    let value: String
    var monospaced: Bool = false

    var body: some View {
        LabeledContent(label) {
            Text(value)
                .font(monospaced ? .system(.body, design: .monospaced) : .body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
                .textSelection(.enabled)
        }
    }
}
