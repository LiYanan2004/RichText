//
//  TextAttributeConverter.swift
//  RichText
//
//  Created by Yanan Li on 2025/10/11.
//

import CoreText
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

enum TextAttributeConverter {
    static func mergingEnvironmentValuesIntoAttributedString(
        _ attributedString: AttributedString,
        configuration: TextViewRenderConfiguration
    ) -> AttributedString {
        var attributedString = attributedString
        
        for run in attributedString.runs {
            var attributes = run.attributes
            
            if let defaultFont = configuration.defaultFont {
                attributes.merge(AttributeContainer([.font : defaultFont]), mergePolicy: .keepCurrent)
            }
            
            attributes.mergeParagraphStyle(mergePolicy: .keepCurrent) { paragraphStyle in
                paragraphStyle.alignment = NSTextAlignment(
                    configuration.multilineTextAlignment,
                    layoutDirection: configuration.layoutDirection
                )
                paragraphStyle.lineSpacing = configuration.lineSpacing
                paragraphStyle.allowsDefaultTighteningForTruncation = configuration.allowsTightening
                paragraphStyle.baseWritingDirection = NSWritingDirection(configuration.layoutDirection)
                paragraphStyle.lineBreakMode = NSLineBreakMode(
                    configuration.truncationMode,
                    lineLimit: configuration.lineLimit
                )
                if let lineHeightSetting = configuration.lineHeightSetting {
                    paragraphStyle.minimumLineHeight = lineHeightSetting.minimum
                    paragraphStyle.maximumLineHeight = lineHeightSetting.maximum
                    paragraphStyle.lineHeightMultiple = lineHeightSetting.multiple
                }
            }
            
            attributedString[run.range].setAttributes(attributes)
        }
        
        return attributedString
    }
    
    static func convertingAndMergingSwiftUIAttributesIntoAttributedString(
        _ attributedString: AttributedString,
        configuration: TextViewRenderConfiguration
    ) -> AttributedString {
        var attributedString = attributedString
        
        for run in attributedString.runs {
            var attributes = run.attributes
            let swiftUIAttributes = attributes.swiftUI
            var convertedAttributes: [NSAttributedString.Key : Any] = [:]
            
            if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, *),
               let font = swiftUIAttributes.font {
                let platformFont = font
                    .resolve(in: configuration.fontResolutionContext)
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
            if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, *),
               let lineHeight = swiftUIAttributes.lineHeight {
                let lineHeightSetting = lineHeight._richTextLineHeightSetting(
                    font: convertedAttributes[.font] as? PlatformFont
                )
                attributes.mergeParagraphStyle(mergePolicy: .keepCurrent) { paragraphStyle in
                    paragraphStyle.minimumLineHeight = lineHeightSetting.minimum
                    paragraphStyle.maximumLineHeight = lineHeightSetting.maximum
                    paragraphStyle.lineHeightMultiple = lineHeightSetting.multiple
                }
            }
            
            attributedString[run.range].setAttributes(attributes)
        }
        
        return attributedString
    }
    
    static func resolveInlinePresentationIntent(
        in attributedString: AttributedString
    ) -> AttributedString {
        var attributedString = attributedString
        
        for run in attributedString.runs {
            let intent = run.attributes.inlinePresentationIntent
            guard let intent else { continue }
            
            var attributes = AttributeContainer()
            if intent.contains(.strikethrough) {
                #if canImport(AppKit)
                attributes.appKit.strikethroughStyle = .single
                #elseif canImport(UIKit)
                attributes.uiKit.strikethroughStyle = .single
                #endif
            }
            
            #if canImport(UIKit)
            if let font = run.uiKit.font {
                let ctFont: CTFont = font
                attributes.uiKit.font = ctFont.applyingInlinePresentationIntent(intent)
            }
            #endif
            
            attributedString[run.range].mergeAttributes(attributes)
        }
        
        return attributedString
    }
    
    @MainActor
    static func mergeRenderConfigurationIntoTextView(
        _ textView: PlatformTextView,
        configuration: TextViewRenderConfiguration
    ) {
        #if canImport(AppKit)
        textView.baseWritingDirection = NSWritingDirection(configuration.layoutDirection)
        textView.alignment = NSTextAlignment(
            configuration.multilineTextAlignment,
            layoutDirection: configuration.layoutDirection
        )
        textView.isAutomaticSpellingCorrectionEnabled = !configuration.isAutocorrectionDisabled
        #elseif canImport(UIKit)
        /* UITextView does not respect to any properties set to that view since its backed storage is an `AttributedString` */
        #endif
        
        let textContainer: NSTextContainer? = textView.textContainer
        if let textContainer {
            updateTextContainer(textContainer, configuration: configuration)
        }
    }
    
    private static func updateTextContainer(
        _ textContainer: NSTextContainer,
        configuration: TextViewRenderConfiguration
    ) {
        let lineLimit = configuration.lineLimit ?? 0
        textContainer.maximumNumberOfLines = lineLimit
        textContainer.lineBreakMode = NSLineBreakMode(
            configuration.truncationMode,
            lineLimit: lineLimit
        )
    }
}

// MARK: - Auxiliary

fileprivate extension CTFont {
    func applyingInlinePresentationIntent(_ intent: InlinePresentationIntent) -> CTFont {
        var symbolicTraits: [CTFontSymbolicTraits] = []
        
        if intent.contains(.code) {
            symbolicTraits.append(.traitMonoSpace)
        }
        if intent.contains(.stronglyEmphasized) {
            symbolicTraits.append(.traitBold)
        }
        if intent.contains(.emphasized) {
            symbolicTraits.append(.traitItalic)
        }
        
        var resolvedFont = CTFontCreateCopyWithAttributes(
            self,
            0, // keep size
            nil, // no transform
            nil // same descriptor
        )
        for trait in symbolicTraits {
            let existingTraits = CTFontGetSymbolicTraits(resolvedFont)
            guard !existingTraits.contains(trait) else { continue }
            
            guard let updatedFont = CTFontCreateCopyWithSymbolicTraits(
                resolvedFont,
                0,
                nil,
                existingTraits.union(trait),
                trait
            ) else {
                continue
            }
            
            resolvedFont = updatedFont
        }
        
        return resolvedFont
    }
}
