//
//  InlineHostingAttachment.swift
//  TextAttachmentExperiment
//
//  Created by LiYanan2004 on 2025/3/27.
//

import SwiftUI

public final class InlineHostingAttachment: NSTextAttachment, Identifiable, @unchecked Sendable {
    var view: AnyView
    let equivalentText: String?
    public let id = UUID()
    
    var state: State
    @Observable
    final class State {
        @ObservationIgnored
        var size: CGSize {
            didSet {
                guard size != oldValue else { return }
                onSizeChange?()
            }
        }
        var origin: CGPoint?
        var onSizeChange: (() -> Void)?
        
        init(size: CGSize, origin: CGPoint? = nil) {
            self.size = size
            self.origin = origin
        }
    }
    
    @MainActor
    public init<Content: View>(_ content: Content, equivalentText: String? = nil) {
        self.view = AnyView(content)
        self.equivalentText = equivalentText

        #if canImport(AppKit)
        let hostingView = NSHostingView(rootView: view)
        let initialSize = hostingView.intrinsicContentSize
        #elseif canImport(UIKit)
        let hostingController = UIHostingController(rootView: view)
        hostingController.view.backgroundColor = .clear
        hostingController.view.setNeedsLayout()
        hostingController.view.layoutIfNeeded()

        let intrinsic = hostingController.view.intrinsicContentSize
        let resolvedIntrinsic = CGSize(
            width: intrinsic.width == UIView.noIntrinsicMetric ? 0 : intrinsic.width,
            height: intrinsic.height == UIView.noIntrinsicMetric ? 0 : intrinsic.height
        )
        let fallback = hostingController.view.sizeThatFits(UIView.layoutFittingCompressedSize)
        let isIntrinsicResolved = resolvedIntrinsic.width > 0 && resolvedIntrinsic.height > 0
        let initialSize = isIntrinsicResolved ? resolvedIntrinsic : fallback
        #else
        let initialSize = CGSize(width: 10, height: 10)
        #endif

        self.state = State(size: initialSize)
        super.init(data: nil, ofType: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func attachmentBounds(
        for textContainer: NSTextContainer?,
        proposedLineFragment lineFrag: CGRect,
        glyphPosition position: CGPoint,
        characterIndex charIndex: Int
    ) -> CGRect {
        let size = state.size == .zero ? CGSize(width: 10, height: 10) : state.size
        return CGRect(origin: .zero, size: size)
    }
    
    public override func image(
        forBounds imageBounds: CGRect,
        textContainer: NSTextContainer?,
        characterIndex charIndex: Int
    ) -> PlatformImage? {
        return nil
    }
    
    
    public override func viewProvider(
        for parentView: PlatformView?,
        location: any NSTextLocation,
        textContainer: NSTextContainer?
    ) -> NSTextAttachmentViewProvider? {
        return nil
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? InlineHostingAttachment else { return false }
        return self.id == other.id
    }
}

extension InlineHostingAttachment {
    static func == (lhs: InlineHostingAttachment, rhs: InlineHostingAttachment) -> Bool {
        lhs.id == rhs.id
    }
}
