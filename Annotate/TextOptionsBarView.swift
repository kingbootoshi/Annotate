import SwiftUI

enum TextOptionsAction {
    case toggleBackground
    case stepFontSize(Int)
    case done
}

@MainActor
final class TextOptionsModel: ObservableObject {
    @Published var hasBackground: Bool = false
    @Published var fontSize: CGFloat = 18
}

/// Compact option strip that floats above the active text field while a label is edited.
@MainActor
struct TextOptionsBarView: View {
    @ObservedObject var model: TextOptionsModel
    let perform: (TextOptionsAction) -> Void

    var body: some View {
        HStack(spacing: 2) {
            chip("rectangle.fill.on.rectangle.fill", key: "⌘B", lit: model.hasBackground) {
                perform(.toggleBackground)
            }
            chip("textformat.size.smaller", key: "⌘-") { perform(.stepFontSize(-1)) }
            Text("\(Int(model.fontSize))")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.85))
                .frame(minWidth: 26)
            chip("textformat.size.larger", key: "⌘+") { perform(.stepFontSize(1)) }
            chip("checkmark", key: "⌘↩") { perform(.done) }
        }
        .padding(4)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.28)))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(0.32), Color.white.opacity(0.09)],
                        startPoint: .top, endPoint: .bottom),
                    lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.4), radius: 10, y: 4)
        .fixedSize()
    }

    private func chip(_ symbol: String, key: String, lit: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: symbol)
                    .font(.system(size: 11, weight: .medium))
                Text(key)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(lit ? 0.95 : 0.55))
                    .padding(.horizontal, 3)
                    .padding(.vertical, 1)
                    .background(RoundedRectangle(cornerRadius: 3).fill(Color.white.opacity(0.1)))
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 5)
            .foregroundStyle(lit ? Color.white : Color.white.opacity(0.72))
            .background {
                if lit {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.14))
                        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.white.opacity(0.22), lineWidth: 1))
                }
            }
            .contentShape(SwiftUI.Rectangle())
        }
        .buttonStyle(.plain)
    }
}
