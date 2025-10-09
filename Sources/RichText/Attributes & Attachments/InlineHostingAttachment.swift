//
//  InlineHostingAttachment.swift
//  TextAttachmentExperiment
//
//  Created by LiYanan2004 on 2025/3/27.
//

import SwiftUI
import ViewIntrospector

/// An attachment that hosts an inline SwiftUI view with other text fragments.
///
/// This serves as placeholder attachment to allow TextKit engine to correctly layout suroundding text.
///
/// When the underlying platform text view calls its layout function, it will report the origin of all attachments back to SwiftUI view via `Observation` framework.
public final class InlineHostingAttachment: NSTextAttachment, Identifiable, @unchecked Sendable {
    /// The SwiftUI view hosted by the attachment.
    public var view: AnyView
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
    /// By doing that, you will also get better performance since it helps reduce unnecessary re-layouts under the hood,
    /// so **it's recommended to provide explicit id for every single view!**
    ///
    /// If you don't provide an id explicitly, a random UUID will be created.
    /// Whenever ``TextView`` refreshes, your view will be recreated and refreshed (all states will be reset also).
    public var id: AnyHashable
    /// The replacement text of this view for both copy/paste and menu actions.
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
    init<Content: View>(_ content: Content, replacement: AttributedString?) {
        self.view = AnyView(content)
        self.id = ViewIdentity.explicit(content) ?? AnyHashable(UUID())

        #if canImport(AppKit)
        let hostingView = NSHostingView(rootView: view)
        let initialSize = hostingView.intrinsicContentSize
        #elseif canImport(UIKit)
        let hostingController = UIHostingController(rootView: view)
        let initialSize = hostingController.view.intrinsicContentSize
        #else
        let initialSize = CGSize(width: 10, height: 10)
        #endif

        self.state = State(size: initialSize)
        super.init(data: nil, ofType: nil)
        
        self.replacement = replacement
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
        let size: CGSize
        if state.size == .zero {
            size = CGSize(width: 10, height: 10)
        } else if let textContainerSize = textContainer?.size {
            if position.x == .zero, position.x + state.size.width >= textContainerSize.width {
                // full width attachment
                // This kind of view will not mix with other text, so we don't need to adjust height
                size = state.size
            } else {
                // inline attachment
                var font: PlatformFont?
                if let textContentManager = textContainer?.textLayoutManager?.textContentManager as? NSTextContentStorage,
                   let attributedString = textContentManager.attributedString {
                    let effectiveRange = 0 ..< attributedString.length
                    
                    let ranges = [(charIndex - 1 ..< charIndex), (charIndex + 1 ..< charIndex + 2)]
                    if let range = ranges.first(where: {
                        guard effectiveRange.contains($0) else { return false }
                        
                        let lastCharacter = attributedString
                            .attributedSubstring(from: NSRange($0))
                            .string.last
                        guard let lastCharacter else {
                            return true // Skip the check
                        }
                        
                        return !lastCharacter.isNewline
                    }) {
                        font = attributedString.attribute(
                            .font,
                            at: range.lowerBound,
                            effectiveRange: nil
                        ) as? PlatformFont
                    }
                }
                
                size = CGSize(
                    width: state.size.width,
                    height: state.size.height * (1 - _descentFactor(font))
                )
            }
        } else {
            size = state.size
        }
        
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
    
    @inlinable func _descentFactor(_ font: PlatformFont?) -> CGFloat {
        guard let font else {
            return 0.2 // reserve 20% as descent by default.
        }
        
        let lineHeight = abs(font.ascender) + abs(font.descender)
        return abs(font.descender) / lineHeight
    }
}

extension InlineHostingAttachment {
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? InlineHostingAttachment else { return false }
        return self.id == other.id
    }
    
    static func == (lhs: InlineHostingAttachment, rhs: InlineHostingAttachment) -> Bool {
        lhs.id == rhs.id
    }
}
