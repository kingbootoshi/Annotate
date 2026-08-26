import SwiftUI

enum HelpBarAction {
    case tool(ToolType)
    case colorPicker
    case widthPicker
    case toggleFade
    case deleteLast
    case clearAll
    case undo
    case hide
}

@MainActor
struct HelpBarView: View {
    let activeTool: ToolType
    let fadeMode: Bool
    let perform: (HelpBarAction) -> Void

    private static let tools: [(ToolType, ShortcutKey, String)] = [
        (.pen, .pen, "Pen"),
        (.highlighter, .highlighter, "High"),
        (.arrow, .arrow, "Arrow"),
        (.line, .line, "Line"),
        (.rectangle, .rectangle, "Rect"),
        (.circle, .circle, "Circle"),
        (.counter, .counter, "Count"),
        (.text, .text, "Text"),
        (.select, .select, "Select"),
        (.eraser, .eraser, "Erase"),
    ]

    var body: some View {
        HStack(spacing: 5) {
            ForEach(Self.tools, id: \.0) { tool, key, label in
                chip(
                    ShortcutManager.shared.getShortcut(for: key).uppercased(),
                    label,
                    active: activeTool == tool
                ) { perform(.tool(tool)) }
            }
            barDivider
            chip(ShortcutManager.shared.getShortcut(for: .colorPicker).uppercased(), "Color") {
                perform(.colorPicker)
            }
            chip(ShortcutManager.shared.getShortcut(for: .lineWidthPicker).uppercased(), "Width") {
                perform(.widthPicker)
            }
            chip("␣", "Fade", active: fadeMode) { perform(.toggleFade) }
            barDivider
            chip("⌫", "Back") { perform(.deleteLast) }
            chip("⌥⌫", "Clear") { perform(.clearAll) }
            chip("⌘Z", "Undo") { perform(.undo) }
            barDivider
            Button(action: { perform(.hide) }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.55))
            }
            .buttonStyle(.plain)
            .help("Hide shortcut bar (⌥H)")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.78))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
        )
    }

    private var barDivider: some View {
        SwiftUI.Rectangle()
            .fill(Color.white.opacity(0.18))
            .frame(width: 1, height: 18)
            .padding(.horizontal, 2)
    }

    private func chip(
        _ key: String, _ label: String, active: Bool = false, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(key)
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(active ? 0.35 : 0.14))
                    )
                Text(label)
                    .font(.system(size: 11))
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(active ? Color.accentColor.opacity(0.45) : Color.clear)
            )
            .foregroundStyle(.white)
            .contentShape(SwiftUI.Rectangle())
        }
        .buttonStyle(.plain)
    }
}
