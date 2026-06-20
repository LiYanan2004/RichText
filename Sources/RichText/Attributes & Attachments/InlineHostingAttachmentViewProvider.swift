//
//  InlineHostingAttachmentViewProvider.swift
//  RichText
//
//  Created by Yanan Li on 2026/6/18.
//

import SwiftUI

final class InlineHostingAttachmentViewProvider: NSTextAttachmentViewProvider {
    private var inlineHostingAttachment: InlineHostingAttachment? {
        self.textAttachment as? InlineHostingAttachment
    }

    override init(
        textAttachment: NSTextAttachment,
        parentView: PlatformView?,
        textLayoutManager: NSTextLayoutManager?,
        location: any NSTextLocation
    ) {
        self.richTextParentView = parentView
        
        super.init(
            textAttachment: textAttachment,
            parentView: parentView,
            textLayoutManager: textLayoutManager,
            location: location
        )
        tracksTextAttachmentViewBounds = true
    }

    weak var richTextParentView: PlatformView?

    override func loadView() {
        super.loadView()
        view = makeHostingView()
    }

    private func makeHostingView() -> PlatformView {
        guard let inlineHostingAttachment else {
            preconditionFailure("InlineHostingAttachmentViewProvider requires an InlineHostingAttachment.")
        }
        nonisolated(unsafe) let attachment = inlineHostingAttachment
        
        // link hosting attachment with the parent text view for size-driven view invalidation.
        let attachmentHostingTextView = richTextParentView as? InlineAttachmentTextView
        MainActor.assumeIsolated {
            attachment.attachmentsHostingTextView = attachmentHostingTextView
        }
        
        let hostingView = MainActor.assumeIsolated {
            attachment.hostingView
        }
        return hostingView
    }

    override func attachmentBounds(
        for attributes: [NSAttributedString.Key: Any],
        location: any NSTextLocation,
        textContainer: NSTextContainer?,
        proposedLineFragment: CGRect,
        position: CGPoint
    ) -> CGRect {
        // TextKit 2 requests layout bounds from the attachment view provider.
        guard let view, let inlineHostingAttachment else { return .zero }

        let font = attributes[.font] as? PlatformFont
        let baselineDescentRatio = InlineHostingAttachment.baselineDescentRatio(for: font)
        nonisolated(unsafe) let attachment = inlineHostingAttachment
        return MainActor.assumeIsolated {
            attachment.layoutBounds(
                lineFragmentWidth: proposedLineFragment.width,
                intrinsicContentSize: view.intrinsicContentSize,
                baselineDescentRatio: baselineDescentRatio
            )
        }
    }
}
