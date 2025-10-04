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
    
    private func setAttributedString(_ attributedString: AttributedString) {
        guard let _textStorage else { return }
        
        do {
            let attributed = try NSMutableAttributedString(
                attributedString: attributedString.nsAttributedString
            )
            _textStorage.setAttributedString(attributed)
            
            attributed.enumerateAttribute(
                .inlineHostingAttachment,
                in: NSRange(location: 0, length: attributed.length)
            ) { value, range, _ in
                guard let attachment = value as? InlineHostingAttachment else { return }
                attachment.state.onSizeChange = { [weak self] in
                    guard let self else { return }
                    invalidateTextLayout(at: range)
                }
            }
        } catch {
            print("Failed to build attributed string: \(error)")
        }
    }
    
    private func invalidateTextLayout(at range: NSRange) {
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
        updateAttachmentOrigins()
    }
    #elseif canImport(UIKit)
    override func layoutSubviews() {
        super.layoutSubviews()
        updateAttachmentOrigins()
    }
    #endif
    
    private func updateAttachmentOrigins() {
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

fileprivate extension NSTextRange {
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
