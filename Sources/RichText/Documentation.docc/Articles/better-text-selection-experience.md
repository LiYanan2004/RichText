# Better Text Selection Experience

An explaination of what is better in terms of text selection experience.

@Options {
    @AutomaticArticleSubheading(disabled)
}

@Metadata {
    @TitleHeading("Explanation")
}

SwiftUI does offer `.textSelection(.enabled)` view modifier to enable text selection.

@TabNavigator {
    @Tab("SwiftUI") {        
        On macOS, it allows:
        - Full / Partial text selection
        - Full context menu
        
        however, on iOS, it ONLY allows:
        - Full text selection
        - Copy text only
        
        @Video(source: "swiftui-text-selection-on-ios.mp4", poster: "swiftui-text-selection-on-ios-poster.png")
    }

    @Tab("Rich Text") {
        ``TextView`` keeps the experience that already available on macOS and fixes the experience for iOS, so you can:
        - select partial range of text
        - trigger more actions (e.g. Translate, Lookup, Search, etc.) in the edit menu
        
        @Video(source: "textview-text-selection-on-ios.mp4", poster: "textview-text-selection-on-ios-poster.png")
    }
}
