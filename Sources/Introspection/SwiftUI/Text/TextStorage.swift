//
//  TextStorage.swift
//  Introspection
//
//  Modified by Yanan Li on 2025/10/7.
//  Initial credits to: https://gist.github.com/davidbalbert/eef9c238531217a42b83d6903ef777dc
//

import SwiftUI

extension SwiftUI.Text {
    /// Returns the underlying attributed string used to render the SwiftUI text when it is available.
    public var _attributedString: AttributedString? {
        let mirror = Mirror(reflecting: self)

        if let attrStr = mirror.descendant("storage", "anyTextStorage", "str") as? AttributedString {
            return attrStr
        }

        return nil
    }

    /// Gets the raw text from SwiftUI text, or resolve it into a plain text.
    public var _rawOrResolvedString: String {
        let mirror = Mirror(reflecting: self)
        
        if let plainString = mirror.descendant("storage", "verbatim") as? String {
            return plainString
        }
        
        if let attrStr = mirror.descendant("storage", "anyTextStorage", "str") as? AttributedString {
            return String(attrStr.characters)
        }
        
        if let key = mirror.descendant("storage", "anyTextStorage", "key") as? LocalizedStringKey,
           let resolvedKey = ResolvedLocalizedStringKey(key).localizedString() {
            return resolvedKey
        }
        
        if let format = mirror.descendant("storage", "anyTextStorage", "storage", "format") as? any FormatStyle,
           let input = mirror.descendant("storage", "anyTextStorage", "storage", "input"),
           let formattedString = format.format(any: input) as? String {
            return formattedString
        }
        
        if let formatter = mirror.descendant("storage", "anyTextStorage", "formatter") as? Formatter,
           let object = mirror.descendant("storage", "anyTextStorage", "object"),
           let formattedString = formatter.string(for: object) {
            return formattedString
        }
        
        // Return a string that is resolved using default environment values as fallback.
        return _resolveText(in: SwiftUICore.EnvironmentValues())
    }
}
