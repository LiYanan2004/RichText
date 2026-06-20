//
//  InlineAttachmentTextView+UIKit.swift
//  RichText
//
//  Created by Yanan Li on 2026/6/20.
//

#if canImport(UIKit)

import UIKit

extension InlineAttachmentTextView {
    var textContainerOffset: CGPoint {
        CGPoint(
            x: textContainerInset.left,
            y: textContainerInset.top
        )
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        invalidateIntrinsicContentSize()
        updateInlineAttachmentViews()
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: PlatformView.noIntrinsicMetric, height: PlatformView.noIntrinsicMetric)
    }
    
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
        let rangeToCopy: UITextRange
        if let selected = selectedTextRange, !selected.isEmpty {
            rangeToCopy = selected
        } else if let documentRange = textRange(from: beginningOfDocument, to: endOfDocument) {
            rangeToCopy = documentRange
        } else {
            super.copy(sender)
            return
        }

        let attributedString = attributedText(in: rangeToCopy)
        UIPasteboard.general.setObjects([attributedString])
    }
}

#endif
