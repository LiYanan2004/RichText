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
    // FIXME: This only works for "Copy" and "Search with Google".
    // Loopup, Translate, Share are using original strings
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
    
    // TODO: It would be better to have a way to directly modify the copying item for each attachment. `NSItemProviderWriting` is not working here.
    override func copy(_ sender: Any?) {
        guard let documentRange = textRange(from: beginningOfDocument, to: endOfDocument) else {
            super.copy(sender)
            return
        }
        
        let attributedString = attributedText(in: documentRange)
        UIPasteboard.general.setObjects([attributedString])
    }
    #endif
    
    private func replaceAttachmentWithEquivalentText(
        in attributedString: NSAttributedString
    ) -> NSAttributedString {
        let mutable = NSMutableAttributedString(attributedString: attributedString)
        mutable.enumerateAttribute(
            .inlineHostingAttachment,
            in: NSRange(location: 0, length: mutable.length),
            options: []
        ) { attachment, subrange, _ in
            guard let attachment = attachment as? InlineHostingAttachment,
                  let replacement = attachment.replacement else { return }
            
            let nsAttrString: NSAttributedString
            do {
                let _nsAttrString = try NSMutableAttributedString(
                    attributedString: replacement.nsAttributedString
                )
                let range = NSRange(location: 0, length: _nsAttrString.length)
                _nsAttrString._fixForgroundColorIfNecessary(in: range)
                _nsAttrString._fixFont(self.font, in: range)
                nsAttrString = _nsAttrString
            } catch {
                nsAttrString = NSAttributedString(replacement)
            }
            
            mutable.replaceCharacters(in: subrange, with: nsAttrString)
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

// MARK: - Attachment Positioning

extension InlineAttachmentTextView {
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

// MARK: - Layout

extension InlineAttachmentTextView {
    func invalidateTextLayout(at range: NSRange) {
        guard let textLayoutManager,
              let textContentManager = textLayoutManager.textContentManager else {
            return
        }
    
        let textRange = NSTextRange(range, textContentManager: textContentManager)
        guard let textRange else { return }
        
        textLayoutManager.invalidateLayout(for: textRange)
        textLayoutManager.ensureLayout(for: textRange)
        
        _invalidateTextLayout()
    }
    
    private func _invalidateTextLayout() {
        #if canImport(AppKit)
        needsLayout = true
        setNeedsDisplay(bounds)
        #elseif canImport(UIKit)
        setNeedsLayout()
        setNeedsDisplay()
        #endif
    }
    
    #if canImport(AppKit)
    override func layout() {
        super.layout()
        invalidateIntrinsicContentSize()
        updateAttachmentOrigins()
    }
    #elseif canImport(UIKit)
    override func layoutSubviews() {
        super.layoutSubviews()
        invalidateIntrinsicContentSize()
        updateAttachmentOrigins()
    }
    #endif
}

// MARK: - Auxiliary

extension NSTextRange {
    convenience init?(_ nsRange: NSRange, textContentManager: NSTextContentManager) {
        let documentStart = textContentManager.documentRange.location
        let startLocation = textContentManager.location(
            documentStart,
            offsetBy: nsRange.location
        )
        guard let startLocation else { return nil }
        
        let endLocation = textContentManager.location(
            documentStart,
            offsetBy: nsRange.location + nsRange.length
        )
        self.init(location: startLocation, end: endLocation)
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
    
    func _fixFont(_ font: PlatformFont?, in range: NSRange) {
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
