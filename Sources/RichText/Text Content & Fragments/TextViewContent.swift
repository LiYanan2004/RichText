//
//  TextViewContent.swift
//  RichText
//
//  Created by Yanan Li on 2025/10/2.
//

import SwiftUI

public struct TextViewContent: Hashable {
    public enum Fragment: Hashable {
        case string(String)
        case attributedString(AttributedString)
        case view(InlineHostingAttachment, eqivalentText: String?)
        
        @MainActor
        func asAttributedString() -> AttributedString {
            switch self {
                case .string(let string):
                    return AttributedString(string)
                case .attributedString(let attributedString):
                    return attributedString
                case .view(let attachment, let eqivalentText):
                    let container = AttributeContainer()
                        .inlineHostingAttachment(attachment)
                        .equivalentText(eqivalentText)
                    return AttributedString("\u{FFFC}", attributes: container)
            }
        }
    }

    public var fragments: [Fragment]
    
    public init(_ fragments: Fragment...) {
        self.fragments = fragments
    }
    
    public init(_ fragments: [Fragment]) {
        self.fragments = fragments
    }

    static public func + (lhs: TextViewContent, rhs: TextViewContent) -> TextViewContent {
        TextViewContent(lhs.fragments + rhs.fragments)
    }
    
    public static func += (lhs: inout TextViewContent, rhs: TextViewContent) {
        lhs.fragments += rhs.fragments
    }

    /// Attributed string that contains all content of the text storage.
    ///
    /// `SwiftUI.Font` will be converted to `PlatformFont` starting from OS 26.
    ///
    /// For prior operating system, use `PlatformFont` rather than `SwiftUI.Font` when creating `AttributedString`(since the text view is backed by platform view, `SwiftUI.Font` is not respected.)
    @MainActor
    func attributedString(fontResolutionContext: Font.Context) -> AttributedString {
        var attributedString = fragments.reduce(into: AttributedString()) { result, fragment in
            result += fragment.asAttributedString()
        }
        
        if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, *) {
            for run in attributedString.runs {
                if let swiftUIFont = run.swiftUI.font {
                    let platformFont = swiftUIFont
                        .resolve(in: fontResolutionContext)
                        .ctFont as PlatformFont
                    attributedString[run.range].setAttributes(
                        AttributeContainer(
                            [.font : platformFont]
                        )
                    )
                }
            }
        }
        
        return attributedString
    }
}
