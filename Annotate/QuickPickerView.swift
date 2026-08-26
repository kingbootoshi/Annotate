import Cocoa

final class QuickPickerView: NSView {
    enum Mode {
        case color
        case width
        case fontSize
    }

    static let widthOptions: [CGFloat] = [1, 2, 3, 5, 8, 12, 16, 24]
    static let fontSizeOptions: [CGFloat] = [14, 18, 24, 32, 44, 60, 80, 110]

    let mode: Mode
    private(set) var selectedIndex: Int

    private let cellSize: CGFloat = 46
    private let padding: CGFloat = 12

    var selectedColor: NSColor? {
        guard mode == .color, colorPalette.indices.contains(selectedIndex) else { return nil }
        return colorPalette[selectedIndex]
    }

    var selectedWidth: CGFloat? {
        guard mode == .width, Self.widthOptions.indices.contains(selectedIndex) else { return nil }
        return Self.widthOptions[selectedIndex]
    }

    var selectedFontSize: CGFloat? {
        guard mode == .fontSize, Self.fontSizeOptions.indices.contains(selectedIndex) else { return nil }
        return Self.fontSizeOptions[selectedIndex]
    }

    private var options: [CGFloat] {
        mode == .fontSize ? Self.fontSizeOptions : Self.widthOptions
    }

    private var itemCount: Int {
        mode == .color ? colorPalette.count : options.count
    }

    init(
        mode: Mode, anchor: NSPoint, within bounds: NSRect, currentColor: NSColor,
        currentWidth: CGFloat, currentFontSize: CGFloat = defaultTextAnnotationFontSize
    ) {
        self.mode = mode
        switch mode {
        case .color:
            selectedIndex = colorPalette.firstIndex { $0.isClose(to: currentColor) } ?? 0
        case .width, .fontSize:
            let current = mode == .width ? currentWidth : currentFontSize
            let choices = mode == .fontSize ? Self.fontSizeOptions : Self.widthOptions
            let distances = choices.map { abs($0 - current) }
            selectedIndex = distances.firstIndex(of: distances.min() ?? 0) ?? 0
        }

        let count = mode == .color ? colorPalette.count : (mode == .fontSize ? Self.fontSizeOptions.count : Self.widthOptions.count)
        let size = NSSize(
            width: padding * 2 + cellSize * CGFloat(count),
            height: cellSize + padding * 2
        )
        var origin = NSPoint(x: anchor.x - size.width / 2, y: anchor.y + 28)
        origin.x = max(bounds.minX + 8, min(origin.x, bounds.maxX - size.width - 8))
        if origin.y + size.height > bounds.maxY - 8 {
            origin.y = anchor.y - size.height - 28
        }
        origin.y = max(bounds.minY + 8, min(origin.y, bounds.maxY - size.height - 8))

        super.init(frame: NSRect(origin: origin, size: size))
        wantsLayer = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func updateSelection(mouseInSuperview point: NSPoint) {
        let local = convert(point, from: superview)
        let raw = Int(floor((local.x - padding) / cellSize))
        let clamped = max(0, min(itemCount - 1, raw))
        guard clamped != selectedIndex else { return }
        selectedIndex = clamped
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        let background = NSBezierPath(roundedRect: bounds, xRadius: 14, yRadius: 14)
        NSColor(white: 0.1, alpha: 0.88).setFill()
        background.fill()
        NSColor(white: 1.0, alpha: 0.15).setStroke()
        background.lineWidth = 1
        background.stroke()

        for index in 0..<itemCount {
            let cellRect = NSRect(
                x: padding + CGFloat(index) * cellSize,
                y: padding,
                width: cellSize,
                height: cellSize
            )
            let isSelected = index == selectedIndex

            switch mode {
            case .color:
                drawColorCell(colorPalette[index], in: cellRect, selected: isSelected)
            case .width:
                drawWidthCell(Self.widthOptions[index], in: cellRect, selected: isSelected)
            case .fontSize:
                drawFontSizeCell(Self.fontSizeOptions[index], in: cellRect, selected: isSelected)
            }
        }
    }

    private func drawColorCell(_ color: NSColor, in rect: NSRect, selected: Bool) {
        let diameter: CGFloat = selected ? 36 : 26
        let dot = centeredCircle(in: rect, diameter: diameter)
        color.setFill()
        dot.fill()

        if selected {
            let ring = centeredCircle(in: rect, diameter: diameter + 6)
            NSColor.white.setStroke()
            ring.lineWidth = 2
            ring.stroke()
        }
    }

    private func drawWidthCell(_ width: CGFloat, in rect: NSRect, selected: Bool) {
        let diameter = min(6 + width * 1.3, 36)
        let dot = centeredCircle(in: rect, diameter: diameter)
        (selected ? NSColor.white : NSColor(white: 0.85, alpha: 0.9)).setFill()
        dot.fill()

        if selected {
            let ring = centeredCircle(in: rect, diameter: min(diameter + 8, 44))
            NSColor.white.setStroke()
            ring.lineWidth = 2
            ring.stroke()
        }
    }

    private func drawFontSizeCell(_ size: CGFloat, in rect: NSRect, selected: Bool) {
        let glyphSize = min(10 + size * 0.28, 40)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: glyphSize, weight: .bold),
            .foregroundColor: selected ? NSColor.white : NSColor(white: 0.85, alpha: 0.9),
        ]
        let glyph = NSAttributedString(string: "A", attributes: attributes)
        let glyphBounds = glyph.size()
        glyph.draw(at: NSPoint(x: rect.midX - glyphBounds.width / 2, y: rect.midY - glyphBounds.height / 2))

        if selected {
            let ring = centeredCircle(in: rect, diameter: 44)
            NSColor.white.setStroke()
            ring.lineWidth = 2
            ring.stroke()
        }
    }

    private func centeredCircle(in rect: NSRect, diameter: CGFloat) -> NSBezierPath {
        NSBezierPath(
            ovalIn: NSRect(
                x: rect.midX - diameter / 2,
                y: rect.midY - diameter / 2,
                width: diameter,
                height: diameter
            ))
    }
}
