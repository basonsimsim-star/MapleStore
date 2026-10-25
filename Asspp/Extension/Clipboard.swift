//
//  Clipboard.swift
//  Asspp
//

import SwiftUI

func copyToClipboard(_ text: String?) {
    guard let text, !text.isEmpty else { return }
    #if canImport(UIKit)
        UIPasteboard.general.string = text
    #elseif canImport(AppKit) && !canImport(UIKit)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    #endif
}
