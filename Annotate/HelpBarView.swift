import SwiftUI

enum HelpBarAction {
    case tool(ToolType)
    case colorPicker
    case widthPicker
    case toggleFade
    case deleteLast
    case clearAll
    case undo
}

@MainActor
final class HelpBarModel: ObservableObject {
    @Published var activeTool: ToolType = .pen
    @Published var fadeMode: Bool = true
    @Published var shortcutsVersion = 0
}

@MainActor
struct HelpBarView: View {
    @ObservedObject var model: HelpBarModel
    let perform: (HelpBarAction) -> Void

    @Namespace private var lensSpace

    private static let tools: [(ToolType, ShortcutKey, String)] = [
        (.pen, .pen, "paintbrush.pointed.fill"),
        (.highlighter, .highlighter, "highlighter"),
        (.arrow, .arrow, "arrow.up.right"),
        (.line, .line, "line.diagonal"),
        (.rectangle, .rectangle, "rectangle"),
        (.circle, .circle, "circle"),
        (.counter, .counter, "number"),
        (.text, .text, "textformat"),
        (.select, .select, "cursorarrow"),
        (.eraser, .eraser, "eraser"),
    ]

    var body: some View {
        HStack(spacing: 10) {
            segment {
                ForEach(Self.tools, id: \.0) { tool, key, symbol in
                    toolButton(tool, key: key, symbol: symbol)
                }
            }
            segment {
                utilityButton(
                    "drop", key: ShortcutManager.shared.getShortcut(for: .colorPicker)
                ) { perform(.colorPicker) }
                utilityButton(
                    "lineweight", key: ShortcutManager.shared.getShortcut(for: .lineWidthPicker)
                ) { perform(.widthPicker) }
                utilityButton(
                    "circle.lefthalf.filled", key: "␣", lit: model.fadeMode
                ) { perform(.toggleFade) }
            }
            segment {
                utilityButton("arrow.backward", key: "⌫") { perform(.deleteLast) }
                utilityButton("trash", key: "⌥⌫") { perform(.clearAll) }
                utilityButton("arrow.uturn.backward", key: "⌘Z") { perform(.undo) }
            }
        }
        .id(model.shortcutsVersion)
    }

    private func segment<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 2) { content() }
            .padding(5)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.black.opacity(0.28))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.white.opacity(0.32), Color.white.opacity(0.09)],
                            startPoint: .top, endPoint: .bottom),
                        lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.45), radius: 19, y: 7)
    }

    private func toolButton(_ tool: ToolType, key: ShortcutKey, symbol: String) -> some View {
        let isActive = model.activeTool == tool
        return HoverScaleButton(action: { perform(.tool(tool)) }) {
            HStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 13, weight: .medium))
                keycap(ShortcutManager.shared.getShortcut(for: key).uppercased(), lit: isActive)
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .foregroundStyle(isActive ? Color.white : Color.white.opacity(0.72))
            .background {
                if isActive {
                    RoundedRectangle(cornerRadius: 13)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.24), Color.white.opacity(0.11)],
                                startPoint: .top, endPoint: .bottom)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 13)
                                .strokeBorder(Color.white.opacity(0.32), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.3), radius: 7, y: 3)
                        .matchedGeometryEffect(id: "lens", in: lensSpace)
                }
            }
        }
    }

    private func utilityButton(
        _ symbol: String, key: String, lit: Bool = false, action: @escaping () -> Void
    ) -> some View {
        HoverScaleButton(action: action) {
            HStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 13, weight: .medium))
                keycap(key.uppercased(), lit: lit)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .foregroundStyle(lit ? Color.white : Color.white.opacity(0.72))
            .background {
                if lit {
                    RoundedRectangle(cornerRadius: 13)
                        .fill(Color.white.opacity(0.14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 13)
                                .strokeBorder(Color.white.opacity(0.22), lineWidth: 1)
                        )
                }
            }
        }
    }

    private func keycap(_ text: String, lit: Bool) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundStyle(Color.white.opacity(lit ? 0.95 : 0.55))
            .fixedSize()
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.1))
            )
    }
}

@MainActor
private struct HoverScaleButton<Label: View>: View {
    let action: () -> Void
    @ViewBuilder let label: () -> Label
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            label()
                .contentShape(SwiftUI.Rectangle())
        }
        .buttonStyle(.plain)
        .scaleEffect(hovering ? 1.07 : 1)
        .animation(.spring(response: 0.22, dampingFraction: 0.6), value: hovering)
        .onHover { hovering = $0 }
    }
}
