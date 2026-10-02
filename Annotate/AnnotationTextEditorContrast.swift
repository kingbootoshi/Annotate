import Cocoa

/// Focused-editor chrome for in-place text annotations.
///
/// AppKit's shared field editor follows the window appearance, so in Dark Mode it
/// paints a dark fill over the field. The editor is kept transparent instead, so the
/// field's own fill (the label pill from `OverlayView.labelPillColor`, or clear) is
/// exactly what the committed label will look like.
///
/// Appearance is derived from the (board-adapted) annotation color: dark text gets
/// an Aqua editor, light text gets a Dark Aqua editor.
enum AnnotationTextEditorContrast {
    static func usesLightEditor(for textColor: NSColor) -> Bool {
        textColor.contrastingColor() == .white
    }

    static func appearance(for textColor: NSColor) -> NSAppearance {
        let name: NSAppearance.Name = usesLightEditor(for: textColor) ? .aqua : .darkAqua
        return NSAppearance(named: name) ?? .currentDrawing()
    }

    @MainActor
    static func apply(to textField: NSTextField, textColor: NSColor) {
        textField.textColor = textColor
        (textField.cell as? NSTextFieldCell)?.textColor = textColor
        textField.appearance = appearance(for: textColor)
    }

    @MainActor
    static func apply(to editor: NSText, textColor: NSColor) {
        editor.appearance = appearance(for: textColor)
        editor.textColor = textColor
        editor.drawsBackground = false
        guard let textView = editor as? NSTextView else { return }
        textView.insertionPointColor = textColor
        textView.selectedTextAttributes = [
            .backgroundColor: NSColor.selectedTextBackgroundColor,
            .foregroundColor: NSColor.selectedTextColor,
        ]
    }
}
