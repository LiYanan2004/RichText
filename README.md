# RichText

Supplementary TextView for SwiftUI that provides better text selection experience, as well as enabling native view embedding using declarative syntax.

Powered by **TextKit 2**. Requires Xcode 26 or later to build.

## Requirement

- iOS 17.0+
- macOS 14.0+

## Getting Started

Add **RichText** as a dependency in your Swift Package Manager manifest.

```
.package(url: "https://github.com/LiYanan2004/RichText.git", branch: "main"),
```

Include `RichText` in any targets that need it.

```
.target(
    name: "MyTarget",
    dependencies: [
        .product(name: "RichText", package: "RichText"),
    ]
),
```

### Strings

```
TextView {
    "Hello, RichText!"
}
```

### Attributed Strings

```
let emphasis: AttributedString = {
    var value = AttributedString("Important")
    value.foregroundColor = .red
    value.font = .headline
    return value
}()

var body: some View {
    TextView {
        emphasis
    }
}
```

### SwiftUI `Text`

`Text` values automatically resolve into attributed fragments.

```
TextView {
    Text("Supports SwiftUI text fragments")
}
```

### Inline Attachments

```
TextView {
    "Tap the "
    Text("button").foregroundColor(.blue)
    " to continue "
    Image(systemName: "arrow.right.circle.fill")
}
```

### Embedding SwiftUI Views

```
TextView {
    "Rating: "
    HStack(spacing: 2) {
        ForEach(0..<5) { _ in
            Image(systemName: "star.fill")
                .foregroundStyle(.yellow)
        }
    }
}
```

