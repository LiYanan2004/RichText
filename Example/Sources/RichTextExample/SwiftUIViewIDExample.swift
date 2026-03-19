//
//  EmbeddedViewIDExample.swift
//  RichTextExample
//
//  Created by Yanan Li on 2026/3/11.
//

import SwiftUI
import RichText

struct EmbeddedViewIDExample: View {
    @State private var value = 0.0
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading) {
                Text("As you change the value of this slider, the `body` will be re-computed.")
                    .foregroundStyle(.secondary)
                Slider(value: $value)
            }
            
            TextView {
                "Hello "
                InlineView(id: "globe-icon", replacement: "globe") { // Explicitly bind the identity here.
                    AnimatingGlobeIcon()
                }
                " World"
            }
            .font(.title)
            .font(PlatformFont.preferredFont(forTextStyle: .title1))
        }
    }
    
    struct AnimatingGlobeIcon: View {
        @State private var initialHueOffset = Double.random(in: 0.0...1.0)
        
        var body: some View {
            TimelineView(.animation) { timeline in
                let timeInterval = timeline.date.timeIntervalSinceReferenceDate
                let normalizedHue = ((timeInterval.truncatingRemainder(dividingBy: 6.0)) / 6.0 + initialHueOffset)
                    .truncatingRemainder(dividingBy: 1.0)
                let animatedColor = Color(
                    hue: normalizedHue,
                    saturation: 0.85,
                    brightness: 0.95
                )

                Image(systemName: "globe")
                    .foregroundStyle(animatedColor)
            }
        }
    }
}

#Preview {
    EmbeddedViewIDExample()
        .scenePadding()
}
