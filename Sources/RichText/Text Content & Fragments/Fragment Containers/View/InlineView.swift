//
//  InlineView.swift
//  RichText
//
//  Created by Yanan Li on 2025/10/8.
//

import SwiftUI

public struct InlineView<Content: View>: TextContentProviding {
    public var content: Content
    public var replacement: AttributedString?
    
    public init(
        _ replacement: AttributedString? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.replacement = replacement
        self.content = content()
    }
    
    public var textContent: TextContent {
        TextContent(
            .view(
                InlineHostingAttachment(
                    content,
                    replacement: replacement
                )
            )
        )
    }
}

extension InlineView {
    public init(
        _ replacement: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        var attributedString: AttributedString?
        if let replacement {
            do {
                attributedString = try AttributedString(markdown: replacement)
            } catch {
                attributedString = AttributedString(replacement)
            }
        }
        
        self.init(attributedString, content: content)
    }
    
    public init(
        string: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        let replacement: AttributedString? = if let string {
            AttributedString(stringLiteral: string)
        } else {
            nil
        }
        self.init(replacement, content: content)
    }
}
