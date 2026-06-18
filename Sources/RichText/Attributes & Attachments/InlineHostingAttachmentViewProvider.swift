//
//  InlineHostingAttachmentViewProvider.swift
//  RichText
//
//  Created by Yanan Li on 2026/6/18.
//

import SwiftUI

final class InlineHostingAttachmentViewProvider: NSTextAttachmentViewProvider {
    var inlineHostingAttachment: InlineHostingAttachment! {
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
    var hostingView: PlatformView?

    override func loadView() {
        super.loadView()
        view = makeHostingView()
    }

    private func makeHostingView() -> PlatformView {
        nonisolated(unsafe) let attachment = self.inlineHostingAttachment!
        
        // link hosting attachment with the parent text view for size-driven view invalidation.
        let attachmentHostingTextView = richTextParentView as? InlineAttachmentTextView
        MainActor.assumeIsolated {
            attachment.attachmentsHostingTextView = attachmentHostingTextView
        }
        
        let hostingView = MainActor.assumeIsolated {
            attachment.hostingView
        }
        self.hostingView = hostingView
        
        return hostingView
    }

    override func attachmentBounds(
        for attributes: [NSAttributedString.Key: Any],
        location: any NSTextLocation,
        textContainer: NSTextContainer?,
        proposedLineFragment: CGRect,
        position: CGPoint
    ) -> CGRect {
        guard let view else { return .zero }

        nonisolated(unsafe) let attachment = self.inlineHostingAttachment!
        let size = MainActor.assumeIsolated {
            attachment.sizeThatFits(
                lineFragmentWidth: proposedLineFragment.width,
                intrinsicContentSize: view.intrinsicContentSize
            )
        }

        let attachmentSize = CGSize(
            width: size.width.isFinite ? size.width : 0,
            height: size.height.isFinite ? size.height : 0
        )

        var origin = CGPoint.zero
        if let font = attributes[.font] as? PlatformFont {
            origin.y = _descentFactor(font) * attachmentSize.height * -1
            attachment.ascender = attachmentSize.height + origin.y
        }

        return CGRect(origin: origin, size: attachmentSize)
    }

    @inlinable func _descentFactor(_ font: PlatformFont?) -> CGFloat {
        guard let font else {
            return 0.2 // reserve 20% as descent by default.
        }

        let lineHeight = abs(font.ascender) + abs(font.descender)
        return abs(font.descender) / lineHeight
    }
}
