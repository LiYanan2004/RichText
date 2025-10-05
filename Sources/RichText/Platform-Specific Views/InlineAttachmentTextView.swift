//
//  InlineAttachmentTextView.swift
//  RichText
//
//  Created by Yanan Li on 2025/8/24.
//

import SwiftUI

final class InlineAttachmentTextView: PlatformTextView {
    var _attributedString: AttributedString = .init() {
        willSet { setAttributedString(newValue) }
    }
    
    var textContentManager: NSTextContentManager? {
        textLayoutManager?.textContentManager
    }
    
    override var intrinsicContentSize: CGSize {
        #if canImport(AppKit)
        // FIXME: Is there any efficient way to calculate the height of the view?
        CGSize(width: PlatformView.noIntrinsicMetric, height: _measuredContentHeight)
        #else
        CGSize(width: PlatformView.noIntrinsicMetric, height: PlatformView.noIntrinsicMetric)
        #endif
    }
    
    #if canImport(AppKit)
    override func attributedSubstring(
        forProposedRange range: NSRange,
        actualRange: NSRangePointer?
    ) -> NSAttributedString? {
        guard let original = super.attributedSubstring(
            forProposedRange: range,
            actualRange: actualRange
        ) else { return nil }
        
        return replaceAttachmentWithEquivalentText(
            in: original
        )
    }
    #else
    override func attributedText(in range: UITextRange) -> NSAttributedString {
        replaceAttachmentWithEquivalentText(
            in: super.attributedText(in: range)
        )
    }

    override func text(in range: UITextRange) -> String? {
        return attributedText(in: range).string
    }
    #endif
    
    private func replaceAttachmentWithEquivalentText(
        in attributedString: NSAttributedString
    ) -> NSAttributedString {
        let mutable = NSMutableAttributedString(attributedString: attributedString)
        mutable.enumerateAttribute(
            .attachment,
            in: NSRange(location: 0, length: mutable.length),
            options: []
        ) { value, subrange, _ in
            guard let hosting = value as? InlineHostingAttachment else { return }
            if let replacement = hosting.equivalentText {
                mutable.replaceCharacters(in: subrange, with: replacement)
            }
        }
        return mutable
    }
    
    private func setAttributedString(_ attributedString: AttributedString) {
        guard let _textStorage else { return }
        
        do {
            let attributed = try NSMutableAttributedString(
                attributedString: attributedString.nsAttributedString
            )
            let range = NSRange(location: 0, length: attributed.length)
            
            attributed._fixForgroundColorIfNecessary(in: range)
            attributed._fixFont(self.font, in: range)
            attributed.enumerateAttribute(
                .inlineHostingAttachment,
                in: range
            ) { value, range, _ in
                guard let attachment = value as? InlineHostingAttachment else { return }
                attachment.state.onSizeChange = { [weak self] in
                    guard let self else { return }
                    invalidateTextLayout(at: range)
                }
            }
            
            _textStorage.setAttributedString(attributed)
        } catch {
            print("Failed to build attributed string: \(error)")
        }
    }
    
}

// MARK: - Helpers

extension InlineAttachmentTextView {
    var textContainerOffset: CGPoint {
        #if canImport(AppKit)
        return textContainerOrigin
        #elseif canImport(UIKit)
        return CGPoint(
            x: textContainerInset.left,
            y: textContainerInset.top
        )
        #else
        return .zero
        #endif
    }
    
    private var _measuredContentHeight: CGFloat {
        guard let textLayoutManager else { return bounds.height }
        
        textLayoutManager.ensureLayout(for: textLayoutManager.documentRange)

        var maxY: CGFloat = 0
        textLayoutManager.enumerateTextSegments(
            in: textLayoutManager.documentRange,
            type: .standard,
            options: [.rangeNotRequired]
        ) { _, segmentFrame, _, _ in
            if segmentFrame.maxY > maxY { maxY = segmentFrame.maxY }
            return true
        }
        
        let totalHeight = maxY + textContainerOffset.y
        return ceil(totalHeight)
    }
    
    func enumerateInlineHostingAttchment(
        in textStorage: NSTextStorage,
        handler: (InlineHostingAttachment, NSRange) -> Void
    ) {
        let range = NSRange(location: 0, length: textStorage.length)
        textStorage.enumerateAttribute(.attachment, in: range) { value, range, _ in
            guard let attachment = value as? InlineHostingAttachment else { return }
            handler(attachment, range)
        }
    }
}

// MARK: - Helpers

extension InlineAttachmentTextView {
    /// An optional value of `NSLayoutManager` for cross-platform code statbility.
    ///
    /// - warning: Calling this would switch to TextKit 1 and cause layout or behavior changes.
    @available(*, deprecated, message: "Calling this would switch to TextKit 1.")
    var _layoutManager: NSLayoutManager? {
        self.layoutManager
    }
    
    /// An optional value of `NSTextContainer` for cross-platform code statbility.
    ///
    /// For UIKit, this is guaranteed to be non-`nil`. For AppKit, this could be `nil`.
    var _textContainer: NSTextContainer? {
        self.textContainer
    }
    
    /// An optional value of `NSTextStorage` for cross-platform code statbility.
    ///
    /// For UIKit, this is guaranteed to be non-`nil`. For AppKit, this could be `nil`.
    var _textStorage: NSTextStorage? {
        self.textStorage
    }
}

// MARK: - Auxiliary

fileprivate extension NSMutableAttributedString {
    func _fixForgroundColorIfNecessary(in range: NSRange) {
        #if canImport(UIKit)
        enumerateAttributes(
            in: range,
            options: []
        ) { attrs, range, _ in
            if attrs[.foregroundColor] == nil {
                addAttribute(.foregroundColor, value: UIColor.label, range: range)
            }
        }
        #endif
    }
    
    #if canImport(AppKit)
    typealias FontType = NSFont
    #else
    typealias FontType = UIFont
    #endif
    
    func _fixFont(_ font: FontType?, in range: NSRange) {
        guard let font else { return }
        
        enumerateAttributes(
            in: range,
            options: []
        ) { attrs, range, _ in
            if attrs[.font] == nil {
                addAttribute(.font, value: font, range: range)
            }
        }
    }
}
