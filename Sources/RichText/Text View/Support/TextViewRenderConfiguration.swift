//
//  TextViewRenderConfiguration.swift
//  RichText
//
//  Created by Codex on 2026/6/20.
//

import SwiftUI

struct TextViewRenderConfiguration {
    struct LineHeightSetting {
        var minimum: CGFloat
        var maximum: CGFloat
        var multiple: CGFloat
    }

    var defaultFont: PlatformFont?
    var fontResolutionContext: Font.Context
    var multilineTextAlignment: TextAlignment
    var layoutDirection: LayoutDirection
    var lineSpacing: CGFloat
    var allowsTightening: Bool
    var lineLimit: Int?
    var truncationMode: Text.TruncationMode
    var lineHeightSetting: LineHeightSetting?
    var isAutocorrectionDisabled: Bool

    @MainActor
    init<Representable: ViewRepresentable>(
        context: RepresentableContext<Representable>
    ) {
        self.init(environmentValues: context.environment)
    }
    
    init(environmentValues: EnvironmentValues) {
        fontResolutionContext = environmentValues.fontResolutionContext
        multilineTextAlignment = environmentValues.multilineTextAlignment
        layoutDirection = environmentValues.layoutDirection
        lineSpacing = environmentValues.lineSpacing
        allowsTightening = environmentValues.allowsTightening
        lineLimit = environmentValues.lineLimit
        truncationMode = environmentValues.truncationMode
        isAutocorrectionDisabled = environmentValues.autocorrectionDisabled

        if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, *) {
            let resolvedFont = (environmentValues.font ?? .default)
                .resolve(in: environmentValues.fontResolutionContext)
                .ctFont as PlatformFont
            defaultFont = resolvedFont
            lineHeightSetting = environmentValues.lineHeight?._richTextLineHeightSetting(
                font: resolvedFont
            )
        } else {
            defaultFont = environmentValues.fallbackPlatformFont
            lineHeightSetting = nil
        }
    }
}

@available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, *)
extension AttributedString.LineHeight {
    func _richTextLineHeightSetting(
        font: PlatformFont?
    ) -> TextViewRenderConfiguration.LineHeightSetting {
        let decoded = try? JSONDecoder().decode(
            _RichTextLineHeight.self,
            from: JSONEncoder().encode(self)
        )
        guard let decoded else {
            return TextViewRenderConfiguration.LineHeightSetting(
                minimum: .zero,
                maximum: .zero,
                multiple: .zero
            )
        }

        var minimum: CGFloat = 0
        var maximum: CGFloat = 0
        var multiple: CGFloat = 0
        if let multipleFactor = decoded.baselineInterval.multiple?.factor {
            multiple = multipleFactor
        } else if let exactHeight = decoded.baselineInterval.exact?.points {
            minimum = exactHeight
            maximum = exactHeight
        } else if let increase = decoded.baselineInterval.leading?.increase, let font {
            let base = font.pointSize
            minimum = base + increase
            maximum = base + increase
        }

        return TextViewRenderConfiguration.LineHeightSetting(
            minimum: minimum,
            maximum: maximum,
            multiple: multiple
        )
    }

    private struct _RichTextLineHeight: Decodable {
        let baselineInterval: BaselineInterval

        struct BaselineInterval: Decodable {
            let multiple: Multiple?
            let variable: Variable?
            let exact: Exact?
            let leading: Leading?

            struct Multiple: Decodable {
                let factor: Double
            }

            struct Exact: Decodable {
                let points: Double
            }

            struct Variable: Decodable { }

            struct Leading: Decodable {
                let increase: Double
            }
        }
    }
}
