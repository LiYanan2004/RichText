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
    
    #if canImport(AppKit)
    private var hostingViewStorage: NSHostingView<AnyView>?
    #endif
    
    #if canImport(UIKit)
    private var hostingController: UIHostingController<AnyView>?
    #endif
    
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
        
        super.init(data: contentData, ofType: uti)
        self.allowsTextAttachmentView = true
    }
    
    @MainActor
    init(
        _ content: some View,
        id: AnyHashable? = nil,
        replacement: AttributedString?
    ) {
        self.rootView = AnyView(content)
        self.replacement = replacement

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

    var ascender: CGFloat?
    
    @MainActor
    lazy var hostingView: PlatformView = {
        #if canImport(AppKit)
        let hostingView = NSHostingView(rootView: rootView)
        hostingView.sizingOptions = .intrinsicContentSize
        self.hostingViewStorage = hostingView
        return hostingView
        #elseif canImport(UIKit)
        let hostingController = UIHostingController(rootView: rootView)
        hostingController.view.backgroundColor = .clear
        self.hostingController = hostingController
        return hostingController.view!
        #endif
    }()
    
    @MainActor
    func updateContent(from attachment: InlineHostingAttachment) -> Bool {
        self.rootView = attachment.rootView
        self.replacement = attachment.replacement
        
        let view = hostingView
        let previousSize = view.intrinsicContentSize
        
        #if canImport(AppKit)
        hostingViewStorage?.rootView = rootView
        let updatedSize = view.intrinsicContentSize
        return previousSize != updatedSize
        #elseif canImport(UIKit)
        hostingController?.rootView = rootView
        let updatedSize = view.intrinsicContentSize
        return previousSize != updatedSize
        #endif
    }
}

extension InlineHostingAttachment {
    static func == (lhs: InlineHostingAttachment, rhs: InlineHostingAttachment) -> Bool {
        lhs.id == rhs.id
    }
}

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
        super.init(
            textAttachment: textAttachment,
            parentView: parentView,
            textLayoutManager: textLayoutManager,
            location: location
        )
        tracksTextAttachmentViewBounds = true
    }
    
    var hostingView: PlatformView?
    
    override func loadView() {
        view = makeHostingView()
    }
    
    private func makeHostingView() -> PlatformView {
        nonisolated(unsafe) let attachment = self.inlineHostingAttachment!
        
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
        let size = MainActor.assumeIsolated {
            view.intrinsicContentSize
        }
        
        var origin = CGPoint.zero
        if let font = attributes[.font] as? PlatformFont {
            origin.y = _descentFactor(font) * size.height * -1
            inlineHostingAttachment.ascender = size.height + origin.y
        }
        
        return CGRect(origin: origin, size: size)
    }
    
    @inlinable func _descentFactor(_ font: PlatformFont?) -> CGFloat {
        guard let font else {
            return 0.2 // reserve 20% as descent by default.
        }
        
        let lineHeight = abs(font.ascender) + abs(font.descender)
        return abs(font.descender) / lineHeight
    }
}
