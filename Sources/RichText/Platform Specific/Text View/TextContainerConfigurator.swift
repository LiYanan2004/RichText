//
//  TextContainerConfigurator.swift
//  RichText
//
//  Created by Yanan Li on 2025/10/11.
//

import SwiftUI

#if canImport(AppKit)
typealias ViewRepresentable = NSViewRepresentable
typealias RepresentableContext = NSViewRepresentableContext
#elseif canImport(UIKit)
typealias ViewRepresentable = UIViewRepresentable
typealias RepresentableContext = UIViewRepresentableContext
#endif

@MainActor
enum TextContainerConfigurator {
    static func updateTextContainer<Representable: ViewRepresentable>(
        _ textContainer: NSTextContainer,
        in context: RepresentableContext<Representable>
    ) {
        if let lineLimit = context.environment.lineLimit {
            textContainer.maximumNumberOfLines = lineLimit
        }
    }
}
