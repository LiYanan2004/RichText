//
//  TextView.swift
//  RichText
//
//  Created by Yanan Li on 2025/8/24.
//

import SwiftUI

/// A rich text container that renders plain strings, attributed strings, and
/// inline SwiftUI views together while offers the same text selection experience.
///
/// You declare the text content by using:
/// - `StringProtocol`-conforming types, such as `String`, `Substring`, etc., for plain-text fragment
/// - `Foundation.AttributedString` for attributed string (or rich text) fragment
/// - `SwiftUI.View` for platform view fragment (without replacement text)
/// - ``InlineView`` for platform view fragment (with optional replacement)
///     - This would have the same effect as previous one, if you choose not providing a replacement text.
///
/// ```swift
/// TextView {
///     "Tap the "
///     InlineView("button") { // Copy the button will get text "button"
///         Button("button") {
///             print("Button Clicked")
///         }
///         .id("button")
///     }
///     " to continue."
/// }
/// ```
///
/// By describing the ``TextContent``, you will be able to embed native view while still getting the text selection experience.
///
/// ### Additional notes on custom view embedding
///
/// **Providing an explicit ``id(_:)`` for each view is recommended**, as it helps reduce unnecessary re-layouts and would help improve performance.
///
/// Plus, if your view owns a state (e.g. you're using `@State`, `@StateObject`, etc. within the view), the identity is also used to preserve the state of a view.
///
/// For more information, check out ``InlineHostingAttachment/id``
///
/// ### SwiftUI View modifiers
///
/// Most of the text-styling view modifiers should work seamlessly with `TextView`.
///
/// ```swift
/// TextView {
///     "Hi there,"
///     LineBreak()
///     "RichText is a SwiftUI framework that provides better Text experience."
/// }
/// .font(.body) // only works on OS 26+
/// .lineSpacing(8)
/// .lineLimit(2)
/// .truncationMode(.tail)
/// ```
///
/// > note:
/// > `.font(_:)` modifier only takes effect on OS 26 and newer platforms. To ensure the consistency, use ``font(_:)-(PlatformFont?)`` instead -- pass in `PlatformFont`.
///
/// > note:
/// > Text modifiers -- such as `baselineOffset(_:)`, `kerning(_:)`, `bold(_:)`, etc. -- are not available since SwiftUI does not expose environment values for those properties. For these use cases, use `AttributedString` instead.
public struct TextView: View {
    public var content: TextContent
    
    @Environment(\.fontResolutionContext) private var fontResolutionContext
    
    /// Creates an instance with the given closure to build text content.
    ///
    /// - Parameter content: A ``TextContent`` that stores all fragments of the text.
    public init(@TextContentBuilder content: () -> TextContent) {
        self.content = content()
    }
    
    public var body: some View {
        #if canImport(AppKit)
        _TextView_AppKit(content: content)
        #elseif canImport(UIKit)
        _TextView_UIKit(content: content)
        #else
        ContentUnavailableView(
            "Content Not Available",
            systemImage: "exclamationmark.triangle"
        )
        #endif
    }
}
