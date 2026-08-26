import Cocoa

class CursorHighlightView: NSView {
    private let manager = CursorHighlightManager.shared
    private let strokeWidth: CGFloat = 2.5

    private var holdRingLayer: CAShapeLayer?
    private var releaseRingLayer: CAShapeLayer?
    private var spotlightLayer: CAShapeLayer?
    private var activeCursorLayer: CAShapeLayer?
    private var activeCursorOutlineLayer: CAShapeLayer?
    private var activeCursorAccentLayer: CAShapeLayer?

    // MARK: - Cached Paths (avoid per-frame allocations)

    private var cachedSpotlightPath: CGPath?
    private var cachedSpotlightSize: CGFloat = 0

    private var cachedCircleOuterPath: CGPath?
    private var cachedCircleInnerPath: CGPath?
    private var cachedCircleSize: CGFloat = 0

    private var cachedCrosshairPath: CGPath?
    private var cachedCrosshairSize: CGFloat = 0

    private var cachedScreenshotCrosshairPath: CGPath?
    private var cachedScreenshotCrosshairSize: CGFloat = 0

    private var cachedBrushGoldPath: CGPath?
    private var cachedBrushBarrelPath: CGPath?
    private var cachedBrushInkPath: CGPath?
    private var cachedBrushSize: CGFloat = 0

    private var cachedOutlineOuterPath: CGPath?
    private var cachedOutlineInnerPath: CGPath?
    private var cachedOutlineScale: CGFloat = 0

    // MARK: - Position Tracking (skip redundant updates)

    private var lastSpotlightPosition: CGPoint = .zero
    private var lastSpotlightVisible: Bool = false
    private var lastSpotlightShadowSize: CGFloat = 0

    override var isFlipped: Bool { false }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        setupLayers()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        setupLayers()
    }

    private func setupLayers() {
        // Spotlight layer (follows cursor when enabled)
        let spotlight = CAShapeLayer()
        spotlight.lineWidth = 0
        spotlight.opacity = 0
        layer?.addSublayer(spotlight)
        spotlightLayer = spotlight

        // Hold ring layer (shown while mouse is down)
        let holdLayer = CAShapeLayer()
        holdLayer.lineWidth = strokeWidth
        holdLayer.fillColor = nil
        holdLayer.opacity = 0
        layer?.addSublayer(holdLayer)
        holdRingLayer = holdLayer

        // Release ring layer (expands and fades on mouse up)
        let releaseLayer = CAShapeLayer()
        releaseLayer.lineWidth = strokeWidth
        releaseLayer.fillColor = nil
        releaseLayer.opacity = 0
        layer?.addSublayer(releaseLayer)
        releaseRingLayer = releaseLayer

        let cursorOutline = CAShapeLayer()
        cursorOutline.opacity = 0
        layer?.addSublayer(cursorOutline)
        activeCursorOutlineLayer = cursorOutline

        let cursorAccent = CAShapeLayer()
        cursorAccent.opacity = 0
        layer?.addSublayer(cursorAccent)
        activeCursorAccentLayer = cursorAccent

        let cursorLayer = CAShapeLayer()
        cursorLayer.opacity = 0
        layer?.addSublayer(cursorLayer)
        activeCursorLayer = cursorLayer
    }

    func updateHoldRingPosition() {
        guard let window = self.window, let ringLayer = holdRingLayer else { return }

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        let globalPosition = manager.cursorPosition
        let cursorOnThisScreen = window.screen?.frame.contains(globalPosition) ?? false

        if manager.shouldShowRing && cursorOnThisScreen {
            let windowPoint = window.convertPoint(fromScreen: globalPosition)
            let localPoint = convert(windowPoint, from: nil)

            let size = manager.currentHoldRingSize
            let rect = CGRect(
                x: -size / 2,
                y: -size / 2,
                width: size,
                height: size
            )

            ringLayer.path = CGPath(ellipseIn: rect, transform: nil)
            ringLayer.position = localPoint
            ringLayer.strokeColor = manager.effectColorStrokeCG
            ringLayer.fillColor = manager.effectColorFillCG
            ringLayer.opacity = 1
        } else {
            ringLayer.opacity = 0
        }

        CATransaction.commit()
    }

    func updateReleaseAnimation() {
        guard let window = self.window, let ringLayer = releaseRingLayer else { return }

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        if let animation = manager.releaseAnimation, !animation.isExpired {
            let windowPoint = window.convertPoint(fromScreen: animation.center)
            let localPoint = convert(windowPoint, from: nil)

            let progress = animation.progress()
            let currentSize = lerp(animation.startSize, animation.maxSize, progress)
            let alpha = Float(1.0 - progress)

            let rect = CGRect(
                x: -currentSize / 2,
                y: -currentSize / 2,
                width: currentSize,
                height: currentSize
            )

            ringLayer.path = CGPath(ellipseIn: rect, transform: nil)
            ringLayer.position = localPoint
            ringLayer.strokeColor = manager.effectColorStrokeCG
            ringLayer.fillColor = manager.effectColorFillCG
            ringLayer.opacity = alpha
        } else {
            ringLayer.opacity = 0
        }

        CATransaction.commit()
    }

    func updateSpotlightPosition() {
        guard let window = self.window, let spotlight = spotlightLayer else { return }

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        let globalPosition = manager.cursorPosition
        let cursorOnThisScreen = window.screen?.frame.contains(globalPosition) ?? false

        if manager.shouldShowCursorHighlight && cursorOnThisScreen {
            let windowPoint = window.convertPoint(fromScreen: globalPosition)
            let localPoint = convert(windowPoint, from: nil)

            let size = manager.spotlightSize
            spotlight.path = spotlightPath(for: size)

            // Only update position if changed
            if localPoint != lastSpotlightPosition {
                spotlight.position = localPoint
                lastSpotlightPosition = localPoint
            }

            // Only update shadow properties when becoming visible or size changed
            let needsShadowUpdate = !lastSpotlightVisible || size != lastSpotlightShadowSize
            if needsShadowUpdate {
                spotlight.fillColor = manager.effectColorSpotlightCG
                spotlight.shadowColor = manager.effectColorCG
                spotlight.shadowRadius = size * 0.4
                spotlight.shadowOpacity = 0.6
                spotlight.shadowOffset = .zero
                lastSpotlightShadowSize = size
            }
            spotlight.opacity = 1
            lastSpotlightVisible = true
        } else {
            spotlight.opacity = 0
            lastSpotlightVisible = false
        }

        CATransaction.commit()
    }

    private func lerp(_ a: CGFloat, _ b: CGFloat, _ t: Double) -> CGFloat {
        a + (b - a) * CGFloat(t)
    }

    // MARK: - Active Cursor

    func updateActiveCursor() {
        guard let window = self.window,
              let cursorLayer = activeCursorLayer,
              let outlineLayer = activeCursorOutlineLayer,
              let accentLayer = activeCursorAccentLayer else { return }

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        let globalPosition = manager.cursorPosition
        let cursorOnThisScreen = window.screen?.frame.contains(globalPosition) ?? false
        let screenHasActiveOverlay = window.screen.map { manager.isOverlayActiveOnScreen($0) } ?? false

        if screenHasActiveOverlay && cursorOnThisScreen && manager.toolCursorKind != .system {
            let windowPoint = window.convertPoint(fromScreen: globalPosition)
            let localPoint = convert(windowPoint, from: nil)

            accentLayer.opacity = 0

            switch manager.toolCursorKind {
            case .system:
                cursorLayer.opacity = 0
                outlineLayer.opacity = 0

            case .crosshair:
                let size = max(24, manager.activeCursorSize * 1.6)

                outlineLayer.path = screenshotCrosshairPath(for: size)
                outlineLayer.position = localPoint
                outlineLayer.fillColor = Self.whiteCG
                outlineLayer.strokeColor = Self.blackCG
                outlineLayer.lineWidth = 0.75
                outlineLayer.opacity = 1

                cursorLayer.opacity = 0

            case .ring:
                let size = max(14, manager.activeCursorSize)

                outlineLayer.path = spotlightPath(for: size)
                outlineLayer.position = localPoint
                outlineLayer.fillColor = nil
                outlineLayer.strokeColor = Self.whiteCG
                outlineLayer.lineWidth = 2
                outlineLayer.opacity = 1

                cursorLayer.path = spotlightPath(for: size + 3)
                cursorLayer.position = localPoint
                cursorLayer.fillColor = nil
                cursorLayer.strokeColor = Self.blackCG
                cursorLayer.lineWidth = 1
                cursorLayer.opacity = 0.6

            case .style:
                switch manager.activeCursorStyle {
            case .outline:
                let scale = manager.systemCursorScale
                let paths = outlineCursorPaths(for: scale)

                outlineLayer.path = paths.outer
                outlineLayer.position = localPoint
                outlineLayer.fillColor = manager.annotationColorCG
                outlineLayer.strokeColor = nil
                outlineLayer.lineWidth = 0
                outlineLayer.opacity = 1

                cursorLayer.path = paths.inner
                cursorLayer.position = localPoint
                cursorLayer.fillColor = Self.blackCG
                cursorLayer.strokeColor = nil
                cursorLayer.lineWidth = 0
                cursorLayer.opacity = 1

            case .circle:
                let size = max(4, manager.effectiveStrokeWidth)
                let strokeWidth: CGFloat = 1.5
                let paths = circlePaths(for: size)

                outlineLayer.path = paths.outer
                outlineLayer.position = localPoint
                outlineLayer.fillColor = nil
                outlineLayer.strokeColor = manager.annotationColorCG
                outlineLayer.lineWidth = strokeWidth
                outlineLayer.opacity = 1

                cursorLayer.path = paths.inner
                cursorLayer.position = localPoint
                cursorLayer.fillColor = manager.inkColorCG
                cursorLayer.strokeColor = nil
                cursorLayer.lineWidth = 0
                cursorLayer.opacity = manager.effectiveStrokeWidth >= 12 ? 1 : 0

            case .crosshair:
                let size = manager.strokeCursorSize
                let thickness = max(2.5, size / 5)

                outlineLayer.opacity = 0

                cursorLayer.path = crosshairPath(for: size)
                cursorLayer.position = localPoint
                cursorLayer.fillColor = nil
                cursorLayer.strokeColor = manager.annotationColorCG
                cursorLayer.lineWidth = thickness
                cursorLayer.opacity = 1

            case .brush:
                let size = manager.strokeCursorSize
                let paths = brushPaths(for: size)
                let dotRadius = max(manager.effectiveStrokeWidth, 2) / 2
                let nibPoint = CGPoint(
                    x: localPoint.x + dotRadius * 0.643,
                    y: localPoint.y + dotRadius * 0.766)

                outlineLayer.path = paths.gold
                outlineLayer.position = nibPoint
                outlineLayer.fillColor = Self.nibGoldCG
                outlineLayer.strokeColor = Self.nibGoldDarkCG
                outlineLayer.lineWidth = 1
                outlineLayer.opacity = 1

                accentLayer.path = paths.barrel
                accentLayer.position = nibPoint
                accentLayer.fillColor = Self.barrelDarkCG
                accentLayer.strokeColor = Self.whiteCG
                accentLayer.lineWidth = 1.2
                accentLayer.opacity = 1

                cursorLayer.path = inkContactDotPath(diameter: max(manager.effectiveStrokeWidth, 2))
                cursorLayer.position = localPoint
                cursorLayer.fillColor = manager.inkColorCG
                cursorLayer.strokeColor = nil
                cursorLayer.lineWidth = 0
                cursorLayer.opacity = 1

            case .none:
                break
                }
            }
        } else {
            cursorLayer.opacity = 0
            outlineLayer.opacity = 0
            accentLayer.opacity = 0
        }

        CATransaction.commit()
    }

    // MARK: - Cached Path Helpers

    private func spotlightPath(for size: CGFloat) -> CGPath {
        if size != cachedSpotlightSize || cachedSpotlightPath == nil {
            let rect = CGRect(x: -size / 2, y: -size / 2, width: size, height: size)
            cachedSpotlightPath = CGPath(ellipseIn: rect, transform: nil)
            cachedSpotlightSize = size
        }
        return cachedSpotlightPath!
    }

    private func screenshotCrosshairPath(for size: CGFloat) -> CGPath {
        if size != cachedScreenshotCrosshairSize || cachedScreenshotCrosshairPath == nil {
            let half = size / 2
            let arm = half * 0.78
            let gap = half * 0.22
            let thickness = max(2.0, size / 13)
            let ht = thickness / 2

            let path = CGMutablePath()
            path.addRect(CGRect(x: gap, y: -ht, width: arm, height: thickness))
            path.addRect(CGRect(x: -gap - arm, y: -ht, width: arm, height: thickness))
            path.addRect(CGRect(x: -ht, y: gap, width: thickness, height: arm))
            path.addRect(CGRect(x: -ht, y: -gap - arm, width: thickness, height: arm))
            cachedScreenshotCrosshairPath = path
            cachedScreenshotCrosshairSize = size
        }
        return cachedScreenshotCrosshairPath!
    }

    private var cachedInkDotPath: CGPath?
    private var cachedInkDotSize: CGFloat = 0

    private func inkContactDotPath(diameter: CGFloat) -> CGPath {
        if diameter != cachedInkDotSize || cachedInkDotPath == nil {
            cachedInkDotPath = CGPath(
                ellipseIn: CGRect(
                    x: -diameter / 2, y: -diameter / 2, width: diameter, height: diameter),
                transform: nil)
            cachedInkDotSize = diameter
        }
        return cachedInkDotPath!
    }

    private func circlePaths(for size: CGFloat) -> (outer: CGPath, inner: CGPath) {
        if size != cachedCircleSize || cachedCircleOuterPath == nil {
            let innerSize = size * 0.4
            let outerRect = CGRect(x: -size / 2, y: -size / 2, width: size, height: size)
            let innerRect = CGRect(x: -innerSize / 2, y: -innerSize / 2, width: innerSize, height: innerSize)
            cachedCircleOuterPath = CGPath(ellipseIn: outerRect, transform: nil)
            cachedCircleInnerPath = CGPath(ellipseIn: innerRect, transform: nil)
            cachedCircleSize = size
        }
        return (cachedCircleOuterPath!, cachedCircleInnerPath!)
    }

    private func crosshairPath(for size: CGFloat) -> CGPath {
        if size != cachedCrosshairSize || cachedCrosshairPath == nil {
            let path = CGMutablePath()
            let halfSize = size / 2
            path.move(to: CGPoint(x: -halfSize, y: 0))
            path.addLine(to: CGPoint(x: halfSize, y: 0))
            path.move(to: CGPoint(x: 0, y: -halfSize))
            path.addLine(to: CGPoint(x: 0, y: halfSize))
            cachedCrosshairPath = path
            cachedCrosshairSize = size
        }
        return cachedCrosshairPath!
    }

    private func brushPaths(for size: CGFloat) -> (gold: CGPath, barrel: CGPath, ink: CGPath) {
        if size != cachedBrushSize || cachedBrushGoldPath == nil {
            let transform = Self.nibTransform(size: size)
            cachedBrushGoldPath = Self.nibGoldPath(with: transform)
            cachedBrushBarrelPath = Self.nibBarrelPath(with: transform)
            cachedBrushInkPath = Self.nibInkPath(with: transform)
            cachedBrushSize = size
        }
        return (cachedBrushGoldPath!, cachedBrushBarrelPath!, cachedBrushInkPath!)
    }

    private static func nibTransform(size: CGFloat) -> CGAffineTransform {
        let scale = size / 28.0
        return CGAffineTransform(rotationAngle: -40 * .pi / 180)
            .scaledBy(x: scale, y: scale)
    }

    private static func nibGoldPath(with transform: CGAffineTransform) -> CGPath {
        let path = CGMutablePath()
        path.move(to: .zero, transform: transform)
        path.addLine(to: CGPoint(x: -4, y: 12), transform: transform)
        path.addQuadCurve(to: CGPoint(x: 4, y: 12), control: CGPoint(x: 0, y: 18), transform: transform)
        path.closeSubpath()
        path.addRect(CGRect(x: -3.5, y: 16, width: 7, height: 4), transform: transform)
        return path
    }

    private static func nibBarrelPath(with transform: CGAffineTransform) -> CGPath {
        var t = transform
        return CGPath(
            roundedRect: CGRect(x: -3.5, y: 20, width: 7, height: 18),
            cornerWidth: 3.5,
            cornerHeight: 3.5,
            transform: &t
        )
    }

    private static func nibInkPath(with transform: CGAffineTransform) -> CGPath {
        var t = transform
        return CGPath(
            ellipseIn: CGRect(x: -1.8, y: 7.7, width: 3.6, height: 3.6),
            transform: &t
        )
    }

    private func outlineCursorPaths(for scale: CGFloat) -> (outer: CGPath, inner: CGPath) {
        if scale != cachedOutlineScale || cachedOutlineOuterPath == nil {
            var transform = CGAffineTransform(scaleX: scale, y: scale)
            cachedOutlineOuterPath = Self.cursorOuterPath.copy(using: &transform)
            cachedOutlineInnerPath = Self.cursorInnerPath.copy(using: &transform)
            cachedOutlineScale = scale
        }
        return (cachedOutlineOuterPath!, cachedOutlineInnerPath!)
    }

    // MARK: - Static Constants

    private static let blackCG: CGColor = NSColor.black.cgColor
    private static let whiteCG: CGColor = NSColor.white.cgColor
    private static let nibGoldCG: CGColor = NSColor(red: 0.89, green: 0.70, blue: 0.25, alpha: 1).cgColor
    private static let nibGoldDarkCG: CGColor = NSColor(red: 0.48, green: 0.37, blue: 0.12, alpha: 1).cgColor
    private static let barrelDarkCG: CGColor = NSColor(red: 0.11, green: 0.11, blue: 0.13, alpha: 1).cgColor

    private static let cursorOuterPath: CGPath = {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: 1))
        path.addLine(to: CGPoint(x: 0, y: -15))
        path.addLine(to: CGPoint(x: 3.3, y: -12.2))
        path.addLine(to: CGPoint(x: 6.1, y: -17.5))
        path.addLine(to: CGPoint(x: 8, y: -16.5))
        path.addLine(to: CGPoint(x: 9.6, y: -15.6))
        path.addLine(to: CGPoint(x: 7, y: -10.8))
        path.addLine(to: CGPoint(x: 11.4, y: -10.8))
        path.closeSubpath()
        return path
    }()

    private static let cursorInnerPath: CGPath = {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 1, y: -1.8))
        path.addLine(to: CGPoint(x: 1, y: -13))
        path.addLine(to: CGPoint(x: 3.5, y: -10.6))
        path.addLine(to: CGPoint(x: 6.3, y: -15.8))
        path.addLine(to: CGPoint(x: 8.2, y: -14.9))
        path.addLine(to: CGPoint(x: 5.4, y: -9.7))
        path.addLine(to: CGPoint(x: 9, y: -9.7))
        path.closeSubpath()
        return path
    }()
}
