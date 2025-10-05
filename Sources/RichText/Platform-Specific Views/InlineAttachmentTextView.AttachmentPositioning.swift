//
//  InlineAttachmentTextView.AttachmentPositioning.swift
//  RichText
//
//  Created by Yanan Li on 2025/10/6.
//

import SwiftUI

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
