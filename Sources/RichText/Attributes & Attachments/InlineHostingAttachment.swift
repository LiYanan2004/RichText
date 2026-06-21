//
//  InlineHostingAttachment.swift
//  TextAttachmentExperiment
//
//  Created by LiYanan2004 on 2025/3/27.
//

import SwiftUI
import Introspection

/// An attachment that hosts an inline SwiftUI view with other text fragments.
///
/// TextKit uses this attachment's bounds to reserve inline space, while the
/// owning platform text view installs and positions the hosted platform view
/// from TextKit layout geometry.
final public class InlineHostingAttachment: NSTextAttachment {
    var rootView: AnyView
    var sizing: HostedAttachmentSizing
    
    #if canImport(AppKit)
    private var hostingController: NSHostingController<AnyView>?
    #endif
    
    #if canImport(UIKit)
    private var hostingController: UIHostingController<AnyView>?
    #endif
    
    @MainActor
    private var isMeasuringAttachmentBounds = false
    @MainActor
    private var isTextLayoutInvalidationScheduled = false
    @MainActor
    weak var attachmentsHostingTextView: InlineAttachmentTextView?
    
    /// The identity of the view.
    ///
    /// Typically, if your view has any state or is initialized with random stuffs,
    /// you will have to explicitly specify an identity to your view hierarchy.
    ///
    /// ```swift
    /// TextView {
    ///     RandomColorView()
    ///         .id("color")
    /// }
    /// ```
    ///
    /// By doing that, you will also get better performance since it helps reduce unnecessary re-layouts under the hood, so **it's recommended to provide explicit id for every single view!**
    ///
    /// If you don't provide an id explicitly, a random UUID will be created.
    /// Whenever ``TextView`` refreshes, your view will be recreated and refreshed (all states will be reset also).
    public var id: AnyHashable
    /// The replacement text of this view used for copy/paste and some menu actions.
    ///
    /// On AppKit, only Copy and Search with Google use the replacement; Lookup, Translate, and Share still use the original text.
    ///
    /// For example, if you copy all text from this ``TextView``, you will get "Hello **World**" (or plain text "Hello World" based on the paste location.)
    ///
    /// ```swift
    /// TextView {
    ///     "Hello"
    ///     InlineView("**World**") {
    ///         GlobeGlyph()
    ///             .id("globe-glyph")
    ///     }
    /// }
    /// ```
    public var replacement: AttributedString?
    
    override init(data contentData: Data?, ofType uti: String?) {
        self.id = UUID()
        self.rootView = AnyView(EmptyView())
        self.sizing = .intrinsic

        super.init(data: contentData, ofType: uti)
        self.allowsTextAttachmentView = true
    }
    
    @MainActor
    init(
        _ content: some View,
        id: AnyHashable? = nil,
        replacement: AttributedString?,
        sizing: HostedAttachmentSizing = .intrinsic
    ) {
        self.rootView = AnyView(content)
        self.replacement = replacement
        self.sizing = sizing

        if let id {
            self.id = AnyHashable(id)
        } else {
            self.id = ViewIdentity.explicit(content) ?? AnyHashable(UUID())
        }

        super.init(data: nil, ofType: nil)
        self.allowsTextAttachmentView = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewProvider(
        for parentView: PlatformView?,
        location: any NSTextLocation,
        textContainer: NSTextContainer?
    ) -> NSTextAttachmentViewProvider? {
        InlineHostingAttachmentViewProvider(
            textAttachment: self,
            parentView: parentView,
            textLayoutManager: textContainer?.textLayoutManager,
            location: location
        )
    }
    
    public override func image(
        forBounds imageBounds: CGRect,
        textContainer: NSTextContainer?,
        characterIndex charIndex: Int
    ) -> PlatformImage? {
        nil
    }
    
    public override func attachmentBounds(
        for textContainer: NSTextContainer?,
        proposedLineFragment lineFragment: CGRect,
        glyphPosition position: CGPoint,
        characterIndex: Int
    ) -> CGRect {
        // TextKit 1 requests layout bounds directly from the attachment.
        let font: PlatformFont? = {
            guard textContainer?.textLayoutManager == nil,
                  let textStorage = textContainer?.layoutManager?.textStorage,
                  characterIndex < textStorage.length else {
                return nil
            }
            return textStorage.attribute(
                .font,
                at: characterIndex,
                effectiveRange: nil
            ) as? PlatformFont
        }()

        let baselineDescentRatio = Self.baselineDescentRatio(for: font)
        nonisolated(unsafe) let attachment = self
        return MainActor.assumeIsolated {
            attachment.layoutBounds(
                lineFragmentWidth: lineFragment.width,
                intrinsicContentSize: attachment.hostingView.intrinsicContentSize,
                baselineDescentRatio: baselineDescentRatio
            )
        }
    }
    
    var ascender: CGFloat?
    
    @MainActor
    private var hostingRootView: AnyView {
        AnyView(
            self.rootView
                .ignoresSafeArea() // Resolves TextKit 1 bug. Make sure to recalculate attachment sizes after the iOS screen size changes.
                .onGeometryChange(for: CGSize.self, of: \.size) { [weak self] _ in
                    self?.hostedViewSizeDidChange()
                }
        )
    }
    
    @MainActor
    lazy var hostingView: PlatformView = {
        #if canImport(AppKit)
        let hostingController = NSHostingController(rootView: hostingRootView)
        hostingController.sizingOptions = .intrinsicContentSize
        self.hostingController = hostingController
        return hostingController.view
        #elseif canImport(UIKit)
        let hostingController = UIHostingController(rootView: hostingRootView)
        hostingController.view.backgroundColor = .clear
        self.hostingController = hostingController
        return hostingController.view!
        #endif
    }()

    @MainActor
    func updateContent(from attachment: InlineHostingAttachment) -> Bool {
        let view = hostingView
        let previousIntrinsicContentSize = view.intrinsicContentSize
        let previousSizing = sizing

        self.rootView = attachment.rootView
        self.replacement = attachment.replacement
        self.sizing = attachment.sizing

        #if canImport(AppKit)
        hostingController?.rootView = hostingRootView
        #elseif canImport(UIKit)
        hostingController?.rootView = hostingRootView
        #endif

        if case .intrinsic = previousSizing,
           case .intrinsic = sizing {
            return previousIntrinsicContentSize != view.intrinsicContentSize
        }
        
        return true
    }

    @MainActor
    func sizeThatFits(
        lineFragmentWidth: CGFloat,
        intrinsicContentSize: CGSize
    ) -> CGSize {
        isMeasuringAttachmentBounds = true
        defer { isMeasuringAttachmentBounds = false }

        let measuredSize: CGSize
        switch sizing {
            case .intrinsic:
                measuredSize = intrinsicContentSize
            case .fittingLineFragment:
                let proposedSize = CGSize(
                    width: max(0, lineFragmentWidth),
                    height: .greatestFiniteMagnitude
                )
                measuredSize = hostingController?.sizeThatFits(in: proposedSize) ?? intrinsicContentSize
        }

        return measuredSize
    }

    @MainActor
    func layoutBounds(
        lineFragmentWidth: CGFloat,
        intrinsicContentSize: CGSize,
        baselineDescentRatio: CGFloat
    ) -> CGRect {
        let measuredSize = sizeThatFits(
            lineFragmentWidth: lineFragmentWidth,
            intrinsicContentSize: intrinsicContentSize
        )
        let attachmentSize = CGSize(
            width: measuredSize.width.isFinite ? measuredSize.width : 0,
            height: measuredSize.height.isFinite ? measuredSize.height : 0
        )
        let origin = CGPoint(
            x: 0,
            y: -baselineDescentRatio * attachmentSize.height
        )

        ascender = attachmentSize.height + origin.y
        return CGRect(origin: origin, size: attachmentSize)
    }

    @MainActor
    private func hostedViewSizeDidChange() {
        guard let attachmentsHostingTextView else { return }
        guard !isMeasuringAttachmentBounds else { return }

        scheduleTextLayoutInvalidation(textView: attachmentsHostingTextView)
    }

    @MainActor
    private func scheduleTextLayoutInvalidation(textView: InlineAttachmentTextView) {
        guard !isTextLayoutInvalidationScheduled else { return }

        isTextLayoutInvalidationScheduled = true
        DispatchQueue.main.async { [weak self, weak textView] in
            guard let self else { return }

            MainActor.assumeIsolated {
                self.isTextLayoutInvalidationScheduled = false
                textView?.invalidateTextLayout(for: self)
            }
        }
    }

    static func baselineDescentRatio(for font: PlatformFont?) -> CGFloat {
        guard let font else { return 0.2 }

        let lineHeight = abs(font.ascender) + abs(font.descender)
        guard lineHeight > 0 else { return 0.2 }
        return abs(font.descender) / lineHeight
    }
}

extension InlineHostingAttachment {
    static func == (lhs: InlineHostingAttachment, rhs: InlineHostingAttachment) -> Bool {
        lhs.id == rhs.id
    }
}
