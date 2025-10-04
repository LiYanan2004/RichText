//
//  TextView.swift
//  RichText
//
//  Created by Yanan Li on 2025/8/24.
//

import SwiftUI

public struct TextView: View {
    private var content: TextViewContent
    @State private var attachments: [InlineHostingAttachment] = []

    public init(@TextViewContentBuilder content: () -> TextViewContent) {
        self.content = content()
    }

    public var body: some View {
        _textView
            .task(id: content) {
                self.attachments = content.attachments
            }
            .overlay(alignment: .topLeading) {
                ForEach(attachments) { attachment in
                    attachment.view
                        .onGeometryChange(for: CGSize.self, of: \.size) { size in
                            attachment.state.size = size
                        }
                        .offset(
                            x: attachment.state.origin?.x ?? 0,
                            y: attachment.state.origin?.y ?? 0
                        )
                        .opacity(attachment.state.origin == nil ? 0 : 1)
                }
            }
    }
    
    private var _textView: some View {
        #if canImport(AppKit)
        _TextView_AppKit(attributedString: content.attributedString)
        #elseif canImport(UIKit)
        _TextView_UIKit(attributedString: content.attributedString)
        #else
        EmptyView()
        #endif
    }
}

// MARK: - Auxiliary

fileprivate extension TextViewContent {
    var attachments: [InlineHostingAttachment] {
        fragments.compactMap { fragment in
            if case let .attachment(attachment) = fragment {
                return attachment
            }
            return nil
        }
    }
}

extension AttributedString {
    var nsAttributedString: NSAttributedString {
        get throws {
            let result = NSMutableAttributedString()

            for run in runs {
                let converted = try NSMutableAttributedString(
                    AttributedString(self[run.range]),
                    including: \.richText
                )
                let range = NSRange(location: 0, length: converted.length)
                #if canImport(AppKit)
                converted.fixFontAttribute(in: range)
                #endif
                
                if let attachment = run.inlineHostingAttachment {
                    converted.addAttribute(
                        .attachment,
                        value: attachment,
                        range: range
                    )
                }

                result.append(converted)
            }

            return NSAttributedString(attributedString: result)
        }
    }
}
