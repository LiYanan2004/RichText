# RichText

A Supplementary TextView for SwiftUI that provides better text selection experience, as well as enabling native view embedding using declarative syntax.

Powered by **TextKit 2**. Requires Xcode 26 or later to build.

## Requirement

- iOS 17.0+
- macOS 14.0+

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

### Inline SwiftUI Views

You can embed SwiftUI view along with other text as well, while preserving text selection capability.

`RichText` will try to extract `SwiftUI.Text` content and convert it into `AttributedString`. If that fails, a plain string will be used instead.

```swift
TextView {
    Text("Hi, This is **RichText**.")
}
```

Other SwiftUI views are added **as an individual text element**, which means text selection will either include or exclude the entire view.

```swift
TextView {
    "Tap the "
    Text("button").foregroundColor(.blue)
    " to continue "
    Image(systemName: "arrow.right.circle.fill")
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

