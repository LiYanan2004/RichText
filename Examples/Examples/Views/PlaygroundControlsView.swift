//
//  PlaygroundControlsView.swift
//  Examples
//

import SwiftUI

struct PlaygroundControlsView: View {
    @Binding var configuration: PlaygroundConfiguration

    var body: some View {
        Section("Typography") {
            ValueSlider(
                "Font size",
                value: $configuration.fontSize,
                range: 12...40,
                step: 1,
                suffix: " pt"
            )
            ValueSlider(
                "Kerning",
                value: $configuration.kerning,
                range: -2...8,
                step: 0.5,
                fractionLength: 1,
                suffix: " pt"
            )
            ValueSlider(
                "Tracking",
                value: $configuration.tracking,
                range: -2...8,
                step: 0.5,
                fractionLength: 1,
                suffix: " pt"
            )
            ValueSlider(
                "Baseline offset",
                value: $configuration.baselineOffset,
                range: -8...8,
                step: 0.5,
                fractionLength: 1,
                suffix: " pt"
            )
            ValueSlider(
                "Line spacing",
                value: $configuration.lineSpacing,
                range: 0...24,
                step: 1,
                suffix: " pt"
            )
        }

        Section("Text Layout") {
            Picker("Alignment", selection: $configuration.textAlignment) {
                ForEach(PlaygroundTextAlignment.allCases) { alignment in
                    Text(alignment.title).tag(alignment)
                }
            }
            .pickerStyle(.segmented)

            Stepper(value: $configuration.lineLimit, in: 0...8) {
                LabeledContent("Line limit", value: lineLimitDescription)
            }

            Picker("Truncation", selection: $configuration.truncationMode) {
                ForEach(PlaygroundTruncationMode.allCases) { truncationMode in
                    Text(truncationMode.title).tag(truncationMode)
                }
            }
            .pickerStyle(.segmented)

            Toggle("Allow tightening", isOn: $configuration.allowsTightening)
        }

        Section("Embedded Rectangle") {
            Stepper(
                value: $configuration.attachmentWidth,
                in: 40...320,
                step: 10
            ) {
                LabeledContent(
                    "Width",
                    value: configuration.attachmentWidth,
                    format: .number.precision(.fractionLength(0))
                )
            }

            Stepper(
                value: $configuration.attachmentHeight,
                in: 20...160,
                step: 10
            ) {
                LabeledContent(
                    "Height",
                    value: configuration.attachmentHeight,
                    format: .number.precision(.fractionLength(0))
                )
            }

            Picker("Sizing", selection: $configuration.attachmentSizing) {
                ForEach(PlaygroundAttachmentSizing.allCases) { sizing in
                    Text(sizing.title).tag(sizing)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var lineLimitDescription: String {
        configuration.lineLimit == 0 ? "Unlimited" : configuration.lineLimit.formatted()
    }
}

#Preview {
    @Previewable @State var configuration = PlaygroundConfiguration.defaultValue

    Form {
        PlaygroundControlsView(configuration: $configuration)
    }
}
