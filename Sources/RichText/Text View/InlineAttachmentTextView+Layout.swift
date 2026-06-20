//
//  InlineAttachmentTextView+Layout.swift
//  RichText
//
//  Created by Yanan Li on 2026/6/20.
//

import SwiftUI

extension InlineAttachmentTextView {
    func invalidateTextLayout(for attachment: InlineHostingAttachment) {
        guard let attachmentRange = inlineAttachmentRangesByID[attachment.id] else {
            return
        }
        
        invalidateTextLayout(at: attachmentRange)
    }
    
    func invalidateTextLayout(at range: NSRange) {
        if let textLayoutManager,
           let textContentManager = textLayoutManager.textContentManager,
           let textRange = NSTextRange(
               range,
               textContentManager: textContentManager
           ) {
            // TK2 path: invalidate the NSTextRange in the text layout manager.
            textLayoutManager.invalidateLayout(for: textRange)
            textLayoutManager.ensureLayout(for: textRange)
        } else if let layoutManager = _layoutManager {
            // TK1 path: invalidate the legacy layout manager by character range.
            layoutManager.invalidateLayout(
                forCharacterRange: range,
                actualCharacterRange: nil
            )
            layoutManager.invalidateDisplay(forCharacterRange: range)
        }
        
        _invalidateTextLayout()
    }
    
    func _invalidateTextLayout() {
        cachedContentHeight = nil
        invalidateIntrinsicContentSize()

        #if canImport(AppKit)
        needsLayout = true
        setNeedsDisplay(bounds)
        #elseif canImport(UIKit)
        setNeedsLayout()
        setNeedsDisplay()
        #endif
    }
}
