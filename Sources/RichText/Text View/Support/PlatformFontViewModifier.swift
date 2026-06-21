//
//  PlatformFontModifier.swift
//  RichText
//
//  Created by Yanan Li on 2025/10/16.
//

import SwiftUI

extension SwiftUI.View {
    /// Sets the default font for the text in this view.
    ///
    /// `SwiftUI.Font.Resolved` is only available on OS 26 and later, and starting with OS 26 `SwiftUI.Font` can be resolved into `PlatformFont`.
    ///
    /// If you target older system versions and want a consistent experience, use this modifier to provide a platform font explicitly.
    ///
    /// ```swift
    /// TextView("TextView")
    ///     .font(PlatformFont.systemFont(ofSize: 28)) // This would work consistently across OS versions
    /// ```
    @inlinable
    public nonisolated func font(_ font: PlatformFont?) -> some View {
        modifier(_PlatformFontModifier(font: font))
    }
}

@usableFromInline
struct _PlatformFontModifier: ViewModifier {
    nonisolated(unsafe) var font: PlatformFont?
    
    @usableFromInline
    nonisolated init(font: PlatformFont?) {
        self.font = font
    }
    
    @usableFromInline
    func body(content: Content) -> some View {
        let swiftUIFont: Font? = if let font {
            Font(font as CTFont)
        } else {
            nil
        }
        content
            .font(swiftUIFont)
            .environment(\.fallbackPlatformFont, font)
    }
}

struct FallbackPlatformFont: EnvironmentKey {
    static var defaultValue: PlatformFont {
        .systemFont(ofSize: PlatformFont.systemFontSize)
    }
}

extension EnvironmentValues {
    @usableFromInline
    var fallbackPlatformFont: PlatformFont? {
        get { self[FallbackPlatformFont.self] }
        set { self[FallbackPlatformFont.self] = newValue ?? FallbackPlatformFont.defaultValue }
    }
}
