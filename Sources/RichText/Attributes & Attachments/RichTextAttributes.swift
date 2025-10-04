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
        
        let inlineHostingAttachmentAttribute: AttributeScopes.RichTextAttributes.InlineHostingAttachmentAttribute
    }
}

extension AttributeDynamicLookup {
    subscript<T: AttributedStringKey>(
        dynamicMember keyPath: KeyPath<AttributeScopes.RichTextAttributes, T>
    ) -> T {
        return self[T.self]
    }
}
