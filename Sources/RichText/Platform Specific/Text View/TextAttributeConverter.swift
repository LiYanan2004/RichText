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
typealias PlatformColor = NSColor
#elseif canImport(UIKit)
typealias ViewRepresentable = UIViewRepresentable
typealias RepresentableContext = UIViewRepresentableContext
typealias PlatformColor = UIColor
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
            var convertedAttributes: [NSAttributedString.Key : Any] = [:]
            
            if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, *) {
                let platformFont = (context.environment.font ?? .default)
                    .resolve(in: context.environment.fontResolutionContext)
                    .ctFont as PlatformFont
                convertedAttributes[.font] = platformFont
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
            convertedAttributes[.paragraphStyle] = paragraphStyle
        
            if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, *),
               let _ = context.environment.lineHeight {
                // TODO: Line Height for OS 26+
            }
            
            attributes.merge(AttributeContainer(convertedAttributes))
            attributedString[run.range].setAttributes(attributes)
        }
        
        return attributedString
    }
    
    static func convertingAndMergingSwiftUIAttributesIntoAttributedString<Representable: ViewRepresentable>(
        _ attributedString: AttributedString,
        context: RepresentableContext<Representable>
    ) -> AttributedString {
        var attributedString = attributedString
        
        for run in attributedString.runs {
            var attributes = run.attributes
            let swiftUIAttributes = attributes.swiftUI
            var convertedAttributes: [NSAttributedString.Key : Any] = [:]
            
            if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, *),
               let font = swiftUIAttributes.font {
                let platformFont = font
                    .resolve(in: context.environment.fontResolutionContext)
                    .ctFont as PlatformFont
                convertedAttributes[.font] = platformFont
            }
            
            if let underlineStyle = swiftUIAttributes.underlineStyle {
                convertedAttributes[.underlineStyle] = NSNumber(
                    value: NSUnderlineStyle(underlineStyle).rawValue
                )
                convertedAttributes[.underlineColor] = underlineStyle.color.map(PlatformColor.init(_:))
            }
            if let strikethroughStyle = swiftUIAttributes.strikethroughStyle {
                convertedAttributes[.strikethroughStyle] = NSNumber(
                    value: NSUnderlineStyle(strikethroughStyle).rawValue
                )
                convertedAttributes[.strikethroughColor] = strikethroughStyle.color.map(PlatformColor.init(_:))
            }
            convertedAttributes[.foregroundColor] = swiftUIAttributes.foregroundColor.map(PlatformColor.init(_:))
            convertedAttributes[.backgroundColor] = swiftUIAttributes.backgroundColor.map(PlatformColor.init(_:))
            convertedAttributes[.kern] = swiftUIAttributes.kern
            convertedAttributes[.tracking] = swiftUIAttributes.tracking
            convertedAttributes[.baselineOffset] = swiftUIAttributes.baselineOffset
            
            attributes.merge(
                AttributeContainer(convertedAttributes)
            )
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

fileprivate extension Text.LineStyle {
    var color: Color? {
        return Mirror(reflecting: self).descendant("color") as? Color
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
