//
//  DynamicView.swift
//  RichTextExample
//
//  Created by Yanan Li on 2026/3/11.
//

import SwiftUI
import RichText

#Preview {
    DynamicViewEmbededTextView()
        .scenePadding()
}

struct DynamicViewEmbededTextView: View {
    @State private var isOpaque: Bool = true
   
    var body: some View {
        VStack {
            Toggle("Opaque", isOn: $isOpaque)
            TextView {
                "Hello "
                ColorfulGlobeIcon()
                    .id("globe-icon") // Explicitly bind the identity here.
                " World"
            }
            .opacity(isOpaque ? 1 : 0.5)
        }
    }
}

struct ColorfulGlobeIcon: View {
    @State var color: Color = .random
    
    var body: some View {
        Image(systemName: "globe")
            .foregroundStyle(color)
            .onTapGesture {
                color = .random
            }
    }
}

fileprivate extension Color {
    static var random: Color {
        Color(
            red: Double.random(in: 0...1),
            green: Double.random(in: 0...1),
            blue: Double.random(in: 0...1)
        )
    }
}
