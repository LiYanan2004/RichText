//
//  InlineAttachmentTextView.swift
//  RichText
//
//  Created by Yanan Li on 2025/8/24.
//

import SwiftUI

final class InlineAttachmentTextView: PlatformTextView {
    var attributedContent: AttributedString = .init() {
        willSet { setAttributedString(newValue) }
    }
    
    private var textContentManager: NSTextContentManager? {
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
    
    private func setAttributedString(_ attributedString: AttributedString) {
        guard let _textStorage else { return }
        
        do {
            let attributed = try NSMutableAttributedString(
                attributedString: attributedString.nsAttributedString
            )
            let range = NSRange(location: 0, length: attributed.length)
            
            attributed._fixForgroundColorIfNecessary(in: range)
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
    
    func updateAttachmentOrigins() {
        guard let textLayoutManager, let _textStorage, let textContentManager else {
            return
        }
        
        textLayoutManager.ensureLayout(
            for: textLayoutManager.documentRange
        )
        
        enumerateInlineHostingAttchment(
            in: _textStorage
        ) { attachment, range in
            let textRange = NSTextRange(
                range,
                textContentManager: textContentManager
            )
            guard let textRange else { return }
            
            var firstFrame: CGRect?
            textLayoutManager.enumerateTextSegments(
                in: textRange,
                type: .standard,
                options: []
            ) { _, segmentFrame, _, _ in
                firstFrame = segmentFrame
                return false
            }
            
            guard let segmentFrame = firstFrame else { return }
            let origin = CGPoint(
                x: segmentFrame.origin.x + textContainerOffset.x,
                y: segmentFrame.origin.y + textContainerOffset.y
            )
            if attachment.state.origin != origin {
                attachment.state.origin = origin
            }
        }
    }
}

// MARK: - Helpers

extension InlineAttachmentTextView {
    private var textContainerOffset: CGPoint {
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
    
    private func enumerateInlineHostingAttchment(
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

// MARK: - Auxiliary

extension InlineAttachmentTextView {
    /// An optional value of `NSLayoutManager` for cross-platform code statbility.
    ///
    /// - warning: Calling this would switch to TextKit 1 and cause layout or behavior changes.
    @available(*, deprecated, message: "Calling this would switch to TextKit 1.")
    private var _layoutManager: NSLayoutManager? {
        self.layoutManager
    }
    
    /// An optional value of `NSTextContainer` for cross-platform code statbility.
    ///
    /// For UIKit, this is guaranteed to be non-`nil`. For AppKit, this could be `nil`.
    private var _textContainer: NSTextContainer? {
        self.textContainer
    }
    
    /// An optional value of `NSTextStorage` for cross-platform code statbility.
    ///
    /// For UIKit, this is guaranteed to be non-`nil`. For AppKit, this could be `nil`.
    private var _textStorage: NSTextStorage? {
        self.textStorage
    }
}

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
}
