//
//  AnimatingGlobeIcon.swift
//  Examples
//

import SwiftUI

struct AnimatingGlobeIcon: View {
    @State private var initialHueOffset = Double.random(in: 0...1)

    var body: some View {
        TimelineView(.animation) { timeline in
            let timeInterval = timeline.date.timeIntervalSinceReferenceDate
            let normalizedHue = (
                timeInterval.truncatingRemainder(dividingBy: 6) / 6 + initialHueOffset
            )
            .truncatingRemainder(dividingBy: 1)

            Image(systemName: "globe")
                .foregroundStyle(
                    Color(
                        hue: normalizedHue,
                        saturation: 0.85,
                        brightness: 0.95
                    )
                )
        }
        .accessibilityLabel("Animated globe")
    }
}

#Preview {
    AnimatingGlobeIcon()
        .font(.title)
        .padding()
}
