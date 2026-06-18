//
//  RatingControl.swift
//  Examples
//

import SwiftUI

struct RatingControl: View {
    @Binding var rating: Int

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { value in
                Button("Rate \(value)", systemImage: value <= rating ? "star.fill" : "star") {
                    rating = value
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.plain)
                .foregroundStyle(.yellow)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Rating")
        .accessibilityValue("\(rating) out of 5 stars")
    }
}

#Preview {
    @Previewable @State var rating = 4

    RatingControl(rating: $rating)
        .padding()
}
