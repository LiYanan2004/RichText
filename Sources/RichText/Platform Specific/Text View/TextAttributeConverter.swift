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
    static func mergingEnvironmentValuesIntoAttributedString<Representable: ViewRepresentable>(
        _ attributedString: AttributedString,
        context: RepresentableContext<Representable>
    ) -> AttributedString {
        var attributedString = attributedString
        
        for run in attributedString.runs {
            var attributes = run.attributes
            
            if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, *) {
                let platformFont = (context.environment.font ?? .default)
                    .resolve(in: context.environment.fontResolutionContext)
                    .ctFont as PlatformFont
                attributes.merge(
                    AttributeContainer([.font : platformFont])
                )
            }
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = NSTextAlignment(
                context.environment.multilineTextAlignment,
                layoutDirection: context.environment.layoutDirection
            )
            paragraphStyle.lineSpacing = context.environment.lineSpacing
            paragraphStyle.allowsDefaultTighteningForTruncation = context.environment.allowsTightening
            paragraphStyle.baseWritingDirection = NSWritingDirection(context.environment.layoutDirection)
            paragraphStyle.lineBreakMode = NSLineBreakMode(context.environment.truncationMode)
            attributes.merge(
                AttributeContainer([.paragraphStyle : paragraphStyle])
            )
            
            if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, *),
               let _ = context.environment.lineHeight {
                // TODO: Line Height for OS 26+
            }
            
            attributedString[run.range].setAttributes(attributes)
        }
        
        return attributedString
    }
    
    static func mergeEnvironmentValueIntoTextView<Representable: ViewRepresentable>(
        _ textView: PlatformTextView,
        context: RepresentableContext<Representable>
    ) {
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
        textContainer.lineBreakMode = NSLineBreakMode(context.environment.truncationMode)
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

fileprivate extension NSWritingDirection {
    init(_ layoutDirection: LayoutDirection) {
        switch layoutDirection {
            case .leftToRight:
                self = .leftToRight
            case .rightToLeft:
                self = .rightToLeft
            @unknown default:
                self = .natural
        }
    }
}
