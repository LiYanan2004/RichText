//
//  EmbeddedRectangle.swift
//  Examples
//

import SwiftUI

struct EmbeddedRectangle: View {
    let width: Double
    let height: Double
    let isHighlighted: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: CGFloat(min(12, height / 4)))
            .fill(isHighlighted ? Color.blue.gradient : Color.gray.gradient)
            .overlay {
                Text(sizeDescription)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.white)
            }
            .frame(
                minWidth: CGFloat(width),
                idealWidth: CGFloat(width),
                maxWidth: .infinity,
                minHeight: CGFloat(height),
                idealHeight: CGFloat(height),
                maxHeight: CGFloat(height)
            )
            .accessibilityLabel("Embedded rectangle")
            .accessibilityValue(sizeDescription)
    }

    private var sizeDescription: String {
        "\(width.formatted(.number.precision(.fractionLength(0)))) × \(height.formatted(.number.precision(.fractionLength(0))))"
    }
}

#Preview {
    EmbeddedRectangle(width: 120, height: 60, isHighlighted: true)
        .padding()
}
