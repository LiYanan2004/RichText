//
//  InlineAttachmentTextView.swift
//  RichText
//
//  Created by Yanan Li on 2025/8/24.
//

import SwiftUI

final class InlineAttachmentTextView: NSTextView {
    
    var attributedContent: AttributedString = .init() {
        willSet { setAttributedString(newValue) }
    }
    
    private func setAttributedString(_ attributedString: AttributedString) {
        guard let textStorage else { return }
        
        do {
            let attributed = try NSMutableAttributedString(
                attributedString: attributedString.nsAttributedString
            )
            attributed.fixAttributes(in: NSRange(location: 0, length: attributed.length))
            textStorage.setAttributedString(attributed)
            
            attributed.enumerateAttribute(
                .inlineHostingAttachmentAttribute,
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
        guard let layoutManager else { return }
        layoutManager.invalidateGlyphs(
            forCharacterRange: range,
            changeInLength: 0,
            actualCharacterRange: nil
        )
        layoutManager.invalidateLayout(
            forCharacterRange: range,
            actualCharacterRange: nil
        )
        
        self.needsLayout = true
        self.setNeedsDisplay(self.bounds)
    }
    
    override func layout() {
        super.layout()
        updateAttachmentOrigins()
    }
    
    private func updateAttachmentOrigins() {
        guard let layoutManager, let textContainer, let textStorage else { return }
        layoutManager.ensureLayout(for: textContainer)
        
        enumerateInlineHostingAttchment(
            in: textStorage
        ) { attachment, range in
            let glyphRange = layoutManager.glyphRange(
                forCharacterRange: range,
                actualCharacterRange: nil
            )
            let rect = layoutManager.boundingRect(
                forGlyphRange: glyphRange,
                in: textContainer
            )
            let origin = rect.origin
            
            if attachment.state.origin != origin {
                attachment.state.origin = origin
            }
        }
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
