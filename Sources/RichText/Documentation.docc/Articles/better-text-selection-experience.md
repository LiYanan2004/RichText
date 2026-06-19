# Improving the text selection experience

An explanation of how RichText improves text selection.

@Options {
    @AutomaticArticleSubheading(disabled)
}

@Metadata {
    @TitleHeading("Explanation")
}

SwiftUI offers the `.textSelection(.enabled)` view modifier to enable text selection.

@TabNavigator {
    @Tab("SwiftUI") {        
        On macOS, it allows:
        - Full and partial text selection
        - A full context menu
        
        However, on iOS, it allows only:
        - Full text selection
        - Copy only
        
        @Video(source: "swiftui-text-selection-on-ios.mp4", poster: "swiftui-text-selection-on-ios-poster.png")
    }

    @Tab("Rich Text") {
        ``RichText/TextView`` preserves the experience on macOS and improves it on iOS, so you can:
        - Select partial ranges of text
        - Trigger more actions (for example, Translate, Lookup, and Search) in the edit menu
        
        @Video(source: "textview-text-selection-on-ios.mp4", poster: "textview-text-selection-on-ios-poster.png")
    }
}

### Adopting Text View

RichText offers convenience initializers so you can replace `Text` with `TextView` and get improved selection behavior:
- ``RichText/TextView/init(_:tableName:bundle:comment:)``
- ``RichText/TextView/init(verbatim:)``
- ``RichText/TextView/init(_:)-(S)``
- ``RichText/TextView/init(_:)-(AttributedString)``
- ``RichText/TextView/init(_:)-(LocalizedStringResource)``

> Note: These initializers do not support view embedding. If you want to embed a view, use ``RichText/TextView/init(content:)`` instead.
