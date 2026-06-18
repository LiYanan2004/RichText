//
//  ValueSlider.swift
//  Examples
//

import SwiftUI

struct ValueSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let fractionLength: Int
    let suffix: String

    init(
        _ title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        fractionLength: Int = 0,
        suffix: String = ""
    ) {
        self.title = title
        self._value = value
        self.range = range
        self.step = step
        self.fractionLength = fractionLength
        self.suffix = suffix
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            LabeledContent(title, value: formattedValue)
            Slider(value: $value, in: range, step: step) {
                Text(title)
            }
        }
    }

    private var formattedValue: String {
        value.formatted(
            .number.precision(.fractionLength(fractionLength))
        ) + suffix
    }
}

#Preview {
    @Previewable @State var value = 17.0

    Form {
        ValueSlider(
            "Font size",
            value: $value,
            range: 12...40,
            step: 1,
            suffix: " pt"
        )
    }
}
