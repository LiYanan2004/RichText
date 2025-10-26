<img src="Resources/logo.png" width=230>

# RichText

A supplementary TextView for SwiftUI that provides better text selection experience, as well as enabling native view embedding using declarative syntax.

Powered by **TextKit 2**.

## Requirements

- Xcode 26.0+
- iOS 17.0+
- macOS 14.0+

## Documentation

You can view documentation on:
- [main @ Swift Package Index](https://swiftpackageindex.com/LiYanan2004/RichText/main/documentation/richtext/)
- [main @ GitHub Pages](https://liyanan2004.github.io/RichText/documentation/richtext/)

## Getting Started

Add **RichText** as a dependency in your Swift Package Manager manifest.

```swift
.package(url: "https://github.com/LiYanan2004/RichText.git", branch: "main"),
```

Include `RichText` in any targets that need it.

```swift
.target(
    name: "MyTarget",
    dependencies: [
        .product(name: "RichText", package: "RichText"),
    ]
),
```

### Plain String & Attributed String

`TextView` provides a result builder that accepts both plain string and `AttributedString`.

```swift
let packageName: AttributedString = {
    var value = AttributedString("RichText")
    value.foregroundColor = .blue
    value.font = .headline
    return value
}()

TextView {
    "Hello, "
    packageName
    "!"
}
```

![](/Resources/init-with-attributed-string.png)

### Inline SwiftUI Views

You can embed SwiftUI view along with other text as well, while preserving text selection capability.

`RichText` will try to extract `SwiftUI.Text` content and convert it into `AttributedString`. If that fails, a plain string will be used instead.

```swift
TextView {
    Text("Hi, This is **RichText**.")
}
```

![](/Resources/init-with-swiftui-text.png)

Other SwiftUI views are added **as an individual text element**, which means text selection will either include or exclude the entire view.

```swift
TextView {
    "Tap the"
    Space()
    Button("button") {
        print("Button Clicked")
    }
    Space()
    "to continue."
}

TextView {
    "Rating: "
    
    // The whole `HStack` will be either selected or de-selected.
    HStack(spacing: 2) {
        ForEach(0..<5) { _ in
            Image(systemName: "star.fill")
                .foregroundStyle(.yellow)
        }
    }
}
```

![](/Resources/inline-view.gif)

#### Dynamic Views

If the embeded view contains its own state, you will need to provide a unique view identifier using `.id(_:)` to bind the view's identity, otherwise, its state will be reset whenever the `textContent` is recomputed.

In the following example, the state of the globe icon will get reset when `ContentView.body` gets re-computed without explicit id specified.

> [!TIP]
> You may need to add `.id(_:)` view modifier directly under embeded view.
>
> Currently, `.id(_:)` inside `View.Body` is not recognizable.

```swift
struct ContentView: View {
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
            .id("globe-icon") // ❌ This does NOT bind the identity of the view internally
    }
}
```

![](/Resources/dynamic-view.gif)

## Troubleshooting

#### SwiftUI `Font` is only reflected on OS 26+

`SwiftUI.Font.Resolved` is only available on OS 26+. We use that to convert a `Font` into `PlatformFont`.

If you need to customize font on older OS version, use `PlatformFont` explicitly.

```swift
TextView("TextView")
    .font(UIFont.systemFont(ofSize: 28)) // This would work consistently across OS versions.
```
