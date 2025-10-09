# Known Issues

Get to know the list of known issues and possible workaround.

@Metadata {
    @TitleHeading("")
}

### TextView

- On macOS, TextView always takes up the maximum available space horizontally

### View Modifiers

- Most of the text style view modifiers, such as `truncationMode(_:)`, `lineSpacing(_:)`, are not support yet
- `.font(_:)` is only available on OS 26 and newer

### Text Replacement

- On macOS, replacement text is not revealed in the context menu. "Translate", "Lookup" and "Share" will not use replaced text
- On iOS, drag & drop a text will drop replacement text.
