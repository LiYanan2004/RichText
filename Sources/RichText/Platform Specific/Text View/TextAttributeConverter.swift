//
//  TextAttributeConverter.swift
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
enum TextAttributeConverter {
    static func mergeEnvironmentValueIntoTextView<Representable: ViewRepresentable>(
        _ textView: PlatformTextView,
        context: RepresentableContext<Representable>
    ) {
        #if canImport(AppKit)
        textView.baseWritingDirection = context.environment.layoutDirection.direction
        textView.alignment = NSTextAlignment(
            context.environment.multilineTextAlignment,
            layoutDirection: context.environment.layoutDirection
        )
        textView.isAutomaticSpellingCorrectionEnabled = !context.environment.autocorrectionDisabled
        #elseif canImport(UIKit)
        textView.semanticContentAttribute = context.environment.layoutDirection.direction
        textView.textAlignment = NSTextAlignment(
            context.environment.multilineTextAlignment,
            layoutDirection: context.environment.layoutDirection
        )
        textView.autocorrectionType = context.environment.autocorrectionDisabled ? .no : .default
        #endif
        
        let textContainer: NSTextContainer? = textView.textContainer
        if let textContainer {
            updateTextContainer(textContainer, context: context)
        }
    }
    
    static private func updateTextContainer<Representable: ViewRepresentable>(
        _ textContainer: NSTextContainer,
        context: RepresentableContext<Representable>
    ) {
        textContainer.maximumNumberOfLines = context.environment.lineLimit ?? 0
        textContainer.lineBreakMode = .init(context.environment.truncationMode)
    }
}

// MARK: - Auxiliary

fileprivate extension NSLineBreakMode {
    init(_ truncationMode: Text.TruncationMode) {
        switch truncationMode {
            case .head:
                self = .byTruncatingHead
            case .tail:
                self = .byTruncatingTail
            case .middle:
                self = .byTruncatingMiddle
            @unknown default:
                self = .byTruncatingTail
        }
    }
}

fileprivate extension NSTextAlignment {
    init(_ textAlignment: TextAlignment, layoutDirection: LayoutDirection) {
        switch textAlignment {
            case .leading:
                self = layoutDirection == .leftToRight ? .left : .right
            case .trailing:
                self = layoutDirection == .leftToRight ? .right : .left
            case .center:
                self = .center
            @unknown default:
                self = .center
        }
    }
}

fileprivate extension LayoutDirection {
    #if canImport(AppKit)
    var direction: NSWritingDirection {
        switch self {
            case .leftToRight:
                return .leftToRight
            case .rightToLeft:
                return .rightToLeft
            @unknown default:
                return .natural
        }
    }
    #elseif canImport(UIKit)
    var direction: UISemanticContentAttribute {
        switch self {
            case .leftToRight:
                return .forceLeftToRight
            case .rightToLeft:
                return .forceRightToLeft
            @unknown default:
                return .unspecified
        }
    }
    #endif
}
