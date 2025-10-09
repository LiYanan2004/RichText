//
//  TextContentBuilder.swift
//  RichText
//
//  Created by Yanan Li on 2025/10/5.
//

import SwiftUI

/// A custom result builder that constructs ``TextContent`` from a closure.
@resultBuilder
public enum TextContentBuilder {
    public static func buildBlock() -> TextContent {
        TextContent()
    }

    public static func buildBlock(_ components: TextContent...) -> TextContent {
        components.reduce(TextContent(), +)
    }

    public static func buildOptional(_ component: TextContent?) -> TextContent {
        component ?? TextContent()
    }

    public static func buildEither(first component: TextContent) -> TextContent {
        component
    }

    public static func buildEither(second component: TextContent) -> TextContent {
        component
    }

    public static func buildArray(_ components: [TextContent]) -> TextContent {
        components.reduce(TextContent(), +)
    }

    // MARK: Expressions
    
    public static func buildExpression(_ expression: TextContent) -> TextContent {
        expression
    }

    @MainActor
    public static func buildExpression(_ expression: some TextContentProviding) -> TextContent {
        expression.textContent
    }

    public static func buildExpression(_ expression: String) -> TextContent {
        TextContent(.string(expression))
    }

    public static func buildExpression(_ expression: AttributedString) -> TextContent {
        TextContent(.attributedString(expression))
    }

    @MainActor
    public static func buildExpression<Content: View>(_ expression: Content) -> TextContent {
        TextContent(.view(InlineHostingAttachment(expression, replacement: nil)))
    }
    
    public static func buildExpression(_ expression: some StringProtocol) -> TextContent {
        buildExpression(String(expression))
    }

    public static func buildExpression(_ expression: Text) -> TextContent {
        if let attributedString = expression._attributedString {
            return TextContent(.attributedString(attributedString))
        }
        
        let content = expression._rawOrResolvedString
        do {
            return try TextContent(.attributedString(AttributedString(markdown: content)))
        } catch {
            return TextContent(.string(content))
        }
    }
}
