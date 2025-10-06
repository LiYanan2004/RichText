//
//  RichTextAttributes.swift
//  RichText
//
//  Created by Yanan Li on 2025/10/3.
//

import Foundation

extension AttributeScopes {
    struct RichTextAttributes : AttributeScope {
        #if canImport(AppKit)
        let appKit: AttributeScopes.AppKitAttributes
        #else
        let uiKit: AttributeScopes.UIKitAttributes
        #endif
        
        let foundation: AttributeScopes.FoundationAttributes
        
        let inlineHostingAttachment: AttributeScopes.RichTextAttributes.InlineHostingAttachmentAttribute
        let equivalentText: AttributeScopes.RichTextAttributes.InlineHostingViewEquivalentTextAttribute
    }
    
    var richText: RichTextAttributes.Type { RichTextAttributes.self }
}

extension AttributeDynamicLookup {
    subscript<T: AttributedStringKey>(
        dynamicMember keyPath: KeyPath<AttributeScopes.RichTextAttributes, T>
    ) -> T {
        return self[T.self]
    }
}
