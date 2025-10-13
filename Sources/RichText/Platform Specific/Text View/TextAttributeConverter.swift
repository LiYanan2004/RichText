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
            paragraphStyle.lineBreakMode = NSLineBreakMode(
                context.environment.truncationMode,
                lineLimit: context.environment.lineLimit
            )
            if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, *),
               let lineHeight = context.environment.lineHeight {
                let (min, max, multiple) = lineHeight._lineSetting(
                    font: convertedAttributes[.font] as? PlatformFont
                )
                paragraphStyle.minimumLineHeight = min
                paragraphStyle.maximumLineHeight = max
                paragraphStyle.lineHeightMultiple = multiple
            }
            convertedAttributes[.paragraphStyle] = paragraphStyle
            
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
            
            if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, *),
               let lineHeight = swiftUIAttributes.lineHeight {
                let paragraphStyle: NSMutableParagraphStyle = (convertedAttributes[.paragraphStyle] as? NSMutableParagraphStyle) ?? NSMutableParagraphStyle()
                
                let (min, max, multiple) = lineHeight._lineSetting(
                    font: convertedAttributes[.font] as? PlatformFont
                )
                paragraphStyle.minimumLineHeight = min
                paragraphStyle.maximumLineHeight = max
                paragraphStyle.lineHeightMultiple = multiple
                
                convertedAttributes[.paragraphStyle] = paragraphStyle
            }
            
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
        #if canImport(AppKit)
        textView.baseWritingDirection = NSWritingDirection(context.environment.layoutDirection)
        textView.alignment = NSTextAlignment(
            context.environment.multilineTextAlignment,
            layoutDirection: context.environment.layoutDirection
        )
        textView.isAutomaticSpellingCorrectionEnabled = !context.environment.autocorrectionDisabled
        #elseif canImport(UIKit)
        /* UITextView does not respect to any properties set to that view since its backed storage is an `AttributedString` */
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
        let lineLimit = context.environment.lineLimit ?? 0
        textContainer.maximumNumberOfLines = lineLimit
        textContainer.lineBreakMode = NSLineBreakMode(
            context.environment.truncationMode,
            lineLimit: lineLimit
        )
    }
}

// MARK: - Auxiliary

fileprivate extension NSLineBreakMode {
    init(_ truncationMode: Text.TruncationMode, lineLimit: Int?) {
        let lineLimit = lineLimit ?? 0
        guard lineLimit > 0 else {
            self = .byWordWrapping
            return
        }
        
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

@available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, *)
fileprivate extension AttributedString.LineHeight {
    func _lineSetting(font: PlatformFont?) -> (min: CGFloat, max: CGFloat, multiple: CGFloat) {
        let decoded = try? JSONDecoder().decode(
            _LineHeight.self,
            from: JSONEncoder().encode(self)
        )
        guard let decoded else { return (.zero, .zero, .zero) }
        
        var min: CGFloat = 0
        var max: CGFloat = 0
        var multiple: CGFloat = 0
        if let multipleFactor = decoded.baselineInterval.multiple?.factor {
            multiple = multipleFactor
        } else if let exactHeight = decoded.baselineInterval.exact?.points {
            min = exactHeight
            max = exactHeight
        } else if let increase = decoded.baselineInterval.leading?.increase, let font {
            let base = font.pointSize
            min = base + increase
            max = base + increase
        }
        
        return (min, max, multiple)
    }
    
    struct _LineHeight: Decodable {
        let baselineInterval: BaselineInterval
        
        struct BaselineInterval: Decodable {
            let multiple: Multiple?
            let variable: Variable?
            let exact: Exact?
            let leading: Leading?
            
            struct Multiple: Decodable {
                let factor: Double
            }
            
            struct Exact: Decodable {
                let points: Double
            }
            
            struct Variable: Decodable { }
            
            struct Leading: Decodable {
                let increase: Double
            }
        }
    }
}
