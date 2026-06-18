//
//  RichTextPlaygroundView.swift
//  Examples
//

import RichText
import SwiftUI

struct RichTextPlaygroundView: View {
    let configuration: PlaygroundConfiguration
    @Binding var isInlineToggleEnabled: Bool
    @Binding var rating: Int
    let resetAction: () -> Void

    var body: some View {
        TextView {
            styledText("Hello, ")
            packageName
            styledText("! ")
            InlineView(
                id: "reset-button",
                replacement: AttributedString("Reset")
            ) {
                Button("Reset", systemImage: "arrow.counterclockwise") {
                    resetAction()
                }
                .buttonStyle(.bordered)
            }

            LineBreak(2)

            Text("SwiftUI.Text supports **inline Markdown**.")

            LineBreak(2)

            inlinePresentationText

            LineBreak(2)

            styledText("Interactive control: ")
            InlineView(
                id: "interactive-toggle",
                replacement: AttributedString("toggle")
            ) {
                Toggle("Enabled", isOn: $isInlineToggleEnabled)
                    .toggleStyle(.switch)
            }

            LineBreak(2)

            styledText("Rating: ")
            InlineView(
                id: "rating-control",
                replacement: AttributedString("\(rating) out of 5 stars")
            ) {
                RatingControl(rating: $rating)
            }

            LineBreak(2)
            
            styledText("Animated identity: ")
            InlineView(
                id: "animated-globe",
                replacement: AttributedString("globe")
            ) {
                AnimatingGlobeIcon()
            }

            LineBreak(2)

            styledText("Adjustable attachment:")
            LineBreak()
            InlineView(
                id: "adjustable-rectangle",
                replacement: AttributedString("[adjustable rectangle]"),
                sizing: configuration.attachmentSizing.hostedAttachmentSizing
            ) {
                EmbeddedRectangle(
                    width: configuration.attachmentWidth,
                    height: configuration.attachmentHeight,
                    isHighlighted: isInlineToggleEnabled
                )
            }
        }
        .font(PlatformFont.systemFont(ofSize: CGFloat(configuration.fontSize)))
        .lineSpacing(CGFloat(configuration.lineSpacing))
        .multilineTextAlignment(configuration.textAlignment.textAlignment)
        .lineLimit(configuration.lineLimit == 0 ? nil : configuration.lineLimit)
        .truncationMode(configuration.truncationMode.truncationMode)
        .allowsTightening(configuration.allowsTightening)
    }

    private var packageName: AttributedString {
        var value = styledText("RichText")
        value.foregroundColor = .blue
        value.font = .headline
        return value
    }

    private var inlinePresentationText: AttributedString {
        var value = styledText("Bold, italic, strikethrough, and code")
        value.inlinePresentationIntent = [
            .emphasized,
            .code,
            .stronglyEmphasized,
            .strikethrough,
        ]
        return value
    }

    private func styledText(_ content: String) -> AttributedString {
        var value = AttributedString(content)
        value.kern = CGFloat(configuration.kerning)
        value.tracking = CGFloat(configuration.tracking)
        value.baselineOffset = CGFloat(configuration.baselineOffset)
        return value
    }
}

#Preview {
    @Previewable @State var isInlineToggleEnabled = true
    @Previewable @State var rating = 4

    ScrollView {
        RichTextPlaygroundView(
            configuration: .defaultValue,
            isInlineToggleEnabled: $isInlineToggleEnabled,
            rating: $rating,
            resetAction: { }
        )
        .padding()
    }
}
