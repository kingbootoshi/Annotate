import XCTest

@testable import Annotate

@MainActor
final class AnnotationTextEditorContrastTests: XCTestCase, Sendable {
    var overlayView: OverlayView!
    var previousAppearance: NSAppearance?
    let customDark = NSColor(calibratedRed: 0.12, green: 0.22, blue: 0.72, alpha: 1)
    let customLight = NSColor(calibratedRed: 0.95, green: 0.9, blue: 0.25, alpha: 1)

    nonisolated override func setUp() {
        super.setUp()
        MainActor.assumeIsolated {
            AppDelegate.shared = nil
            previousAppearance = NSApp.appearance
            BoardManager.shared = BoardManager(userDefaults: TestUserDefaults.create())
            overlayView = OverlayView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
            overlayView.pickerUserDefaultsOverride = TestUserDefaults.create()
        }
    }

    nonisolated override func tearDown() {
        MainActor.assumeIsolated {
            overlayView?.activeTextField?.removeFromSuperview()
            overlayView?.activeTextField = nil
            overlayView?.pickerUserDefaultsOverride = nil
            overlayView = nil
            NSApp.appearance = previousAppearance
            BoardManager.shared = BoardManager()
            previousAppearance = nil
        }
        TestUserDefaults.removeSuite()
        super.tearDown()
    }

    // MARK: - Contrast helper

    func testEditorAppearanceTracksTextLuminance() {
        XCTAssertTrue(AnnotationTextEditorContrast.usesLightEditor(for: .black))
        XCTAssertTrue(AnnotationTextEditorContrast.usesLightEditor(for: .magenta))
        XCTAssertTrue(AnnotationTextEditorContrast.usesLightEditor(for: customDark))

        XCTAssertFalse(AnnotationTextEditorContrast.usesLightEditor(for: .white))
        XCTAssertFalse(AnnotationTextEditorContrast.usesLightEditor(for: .systemYellow))
        XCTAssertFalse(AnnotationTextEditorContrast.usesLightEditor(for: customLight))
    }

    func testEditorAppearanceForNamedColors() {
        XCTAssertEqual(
            AnnotationTextEditorContrast.appearance(for: .black).bestMatch(from: [.aqua, .darkAqua]),
            .aqua
        )
        XCTAssertEqual(
            AnnotationTextEditorContrast.appearance(for: .white).bestMatch(from: [.aqua, .darkAqua]),
            .darkAqua
        )
        XCTAssertEqual(
            AnnotationTextEditorContrast.appearance(for: .systemYellow).bestMatch(from: [.aqua, .darkAqua]),
            .darkAqua
        )
        XCTAssertEqual(
            AnnotationTextEditorContrast.appearance(for: .magenta).bestMatch(from: [.aqua, .darkAqua]),
            .aqua
        )
    }

    // MARK: - Field editor (the native focused editor)

    func testPaddedCellRestylesDarkFieldEditorForBlackText() {
        let editor = NSTextView(frame: NSRect(x: 0, y: 0, width: 200, height: 32))
        editor.appearance = NSAppearance(named: .darkAqua)
        editor.drawsBackground = false
        editor.backgroundColor = .black
        editor.insertionPointColor = .white
        editor.textColor = .white

        let cell = PaddedTextFieldCell()
        cell.textColor = .black
        let configured = cell.setUpFieldEditorAttributes(editor)

        assertEditorContrast(configured, displayedColor: .black)
    }

    func testPaddedCellStylesFieldEditorForPaletteAndCustomColors() {
        for color in editorTestColors {
            let cell = PaddedTextFieldCell()
            cell.textColor = color
            let editor = NSTextView(frame: NSRect(x: 0, y: 0, width: 200, height: 32))
            editor.appearance = NSAppearance(named: .darkAqua)
            assertEditorContrast(
                cell.setUpFieldEditorAttributes(editor),
                displayedColor: color
            )
        }
    }

    func testPaddedCellSelectAndEditKeepFieldEditorContrast() {
        let field = AnnotationTextField(
            frame: NSRect(x: 0, y: 0, width: 200, height: 32)
        )
        let cell = PaddedTextFieldCell()
        field.cell = cell
        AnnotationTextEditorContrast.apply(to: field, textColor: .black)

        let editor = NSTextView(frame: field.bounds)
        cell.select(
            withFrame: field.bounds, in: field, editor: editor, delegate: nil, start: 0, length: 0)
        assertEditorContrast(editor, displayedColor: .black)

        editor.appearance = NSAppearance(named: .darkAqua)
        editor.backgroundColor = .black
        cell.edit(withFrame: field.bounds, in: field, editor: editor, delegate: nil, event: nil)
        assertEditorContrast(editor, displayedColor: .black)
    }

    // MARK: - createTextField across overlay / boards / pill background

    func testCreateTextFieldUsesLightAppearanceForBlackTextInDarkMode() {
        // Reproduction from #101: Dark Mode, no board, black annotation text.
        configureSurface(appearance: .darkAqua, boardEnabled: false)
        overlayView.currentColor = .black

        let field = makeTextField(color: .black, hasBackground: false)

        assertFieldContrast(field, displayedColor: .black, hasBackground: false)
        XCTAssertEqual(
            field.appearance?.bestMatch(from: [.aqua, .darkAqua]),
            .aqua,
            "Black text must force a light field appearance so the native editor is not dark"
        )
    }

    func testCreateTextFieldContrastForNamedAndCustomColorsAcrossSurfaces() throws {
        let surfaces: [(NSAppearance.Name, Bool, String)] = [
            (.darkAqua, false, "normal overlay in Dark Mode"),
            (.aqua, false, "normal overlay in Light Mode"),
            (.aqua, true, "whiteboard"),
            (.darkAqua, true, "blackboard"),
        ]

        for (appearance, boardEnabled, surface) in surfaces {
            for hasBackground in [false, true] {
                for color in editorTestColors {
                    configureSurface(appearance: appearance, boardEnabled: boardEnabled)
                    overlayView.currentColor = color
                    let displayed = overlayView.adaptColorForBoard(
                        color, boardType: overlayView.currentBoardType)

                    let field = makeTextField(color: color, hasBackground: hasBackground)
                    assertFieldContrast(
                        field,
                        displayedColor: displayed,
                        hasBackground: hasBackground,
                        message: "\(surface), hasBackground=\(hasBackground), color=\(color)"
                    )

                    field.stringValue = "Start here"
                    overlayView.finalizeTextAnnotation(field)

                    let committed = try XCTUnwrap(overlayView.textAnnotations.last)
                    XCTAssertTrue(
                        committed.color.isClose(to: color),
                        "Committed color must stay \(color) on \(surface)"
                    )
                    XCTAssertEqual(committed.hasBackground, hasBackground)
                    overlayView.textAnnotations.removeAll()
                    overlayView.currentTextAnnotation = nil
                }
            }
        }
    }

    func testToggleAnnotationBackgroundDoesNotChangeEditorOrCommittedColor() throws {
        configureSurface(appearance: .darkAqua, boardEnabled: false)
        overlayView.currentColor = .black
        overlayView.currentTool = .text
        let field = makeTextField(color: .black, hasBackground: false)
        let originalBackground = field.backgroundColor
        let originalText = field.textColor

        overlayView.currentTextAnnotation?.hasBackground = true
        overlayView.pickerUserDefaults.textBackgroundEnabled = true

        XCTAssertTrue(field.textColor?.isClose(to: originalText ?? .clear) ?? false)
        XCTAssertNil(field.layer?.backgroundColor, "Editing a plain label must not gain a pill mid-edit")
        assertFieldContrast(field, displayedColor: .black, hasBackground: false)

        field.stringValue = "Label"
        overlayView.finalizeTextAnnotation(field)
        let committed = try XCTUnwrap(overlayView.textAnnotations.last)
        XCTAssertTrue(committed.color.isClose(to: .black))
        XCTAssertTrue(committed.hasBackground)
    }

    func testFocusedNativeEditorInDarkWindowStaysReadableForBlackText() throws {
        configureSurface(appearance: .darkAqua, boardEnabled: false)

        let window = OverlayWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        defer {
            window.overlayView.pickerUserDefaultsOverride = nil
            window.close()
        }
        window.appearance = NSAppearance(named: .darkAqua)
        window.overlayView.pickerUserDefaultsOverride = overlayView.pickerUserDefaultsOverride
        window.overlayView.currentColor = .black
        window.overlayView.currentTool = .text
        window.overlayView.currentTextAnnotation = TextAnnotation(
            text: "",
            position: NSPoint(x: 120, y: 120),
            color: .black,
            fontSize: defaultTextAnnotationFontSize
        )
        window.orderFrontRegardless()
        window.makeKeyAndOrderFront(nil)
        window.overlayView.createTextField(at: NSPoint(x: 120, y: 120), withText: "", width: 200)

        let field = try XCTUnwrap(window.overlayView.activeTextField)
        if window.firstResponder !== field && window.firstResponder !== field.currentEditor() {
            window.makeFirstResponder(field)
        }
        assertFieldContrast(field, displayedColor: .black, hasBackground: false)
        let editor = try XCTUnwrap(field.currentEditor(), "Native field editor must be attached")
        assertEditorContrast(editor, displayedColor: .black)

        field.stringValue = "Start here"
        window.overlayView.finalizeTextAnnotation(field)
        XCTAssertTrue(window.overlayView.textAnnotations.last?.color.isClose(to: .black) ?? false)
    }

    func testAnnotationTextFieldBecomeFirstResponderAppliesEditorContrast() throws {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 200),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        defer { window.close() }
        window.appearance = NSAppearance(named: .darkAqua)
        let field = AnnotationTextField(frame: NSRect(x: 20, y: 20, width: 200, height: 32))
        field.cell = PaddedTextFieldCell()
        field.isEditable = true
        field.isSelectable = true
        field.stringValue = "Selected annotation"
        AnnotationTextEditorContrast.apply(to: field, textColor: .systemRed)
        window.contentView?.addSubview(field)
        window.orderFrontRegardless()
        window.makeKeyAndOrderFront(nil)
        XCTAssertTrue(window.makeFirstResponder(field))

        let editor = try XCTUnwrap(
            field.currentEditor() as? NSTextView, "Native field editor must be attached")
        editor.selectAll(nil)
        assertEditorContrast(editor, displayedColor: .systemRed)
        XCTAssertEqual(editor.selectedRange().length, field.stringValue.utf16.count)
        let storedColor = try XCTUnwrap(
            editor.textStorage?.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? NSColor)
        XCTAssertTrue(storedColor.isClose(to: .systemRed), "Selection must preserve annotation color")
    }

    // MARK: - Helpers

    private var editorTestColors: [NSColor] {
        [.black, .white, .systemYellow, .magenta, customDark, customLight]
    }

    private func configureSurface(appearance: NSAppearance.Name, boardEnabled: Bool) {
        NSApp.appearance = NSAppearance(named: appearance)
        BoardManager.shared.isEnabled = boardEnabled
    }

    private func makeTextField(color: NSColor, hasBackground: Bool) -> NSTextField {
        overlayView.currentTool = .text
        overlayView.currentTextAnnotation = TextAnnotation(
            text: "",
            position: NSPoint(x: 100, y: 100),
            color: color,
            fontSize: defaultTextAnnotationFontSize,
            hasBackground: hasBackground
        )
        overlayView.createTextField(at: NSPoint(x: 100, y: 100), withText: "", width: 100)
        return overlayView.activeTextField!
    }

    /// The live field shows exactly the committed pill (or nothing), with an appearance
    /// that keeps the caret and selection readable for the text color.
    private func assertFieldContrast(
        _ field: NSTextField,
        displayedColor: NSColor,
        hasBackground: Bool,
        message: String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertFalse(field.drawsBackground, "the layer paints the pill, not the cell \(message)", file: file, line: line)
        XCTAssertTrue(
            field.textColor?.isClose(to: displayedColor) ?? false,
            "textColor \(displayedColor) \(message)",
            file: file,
            line: line
        )
        let layerFill = field.layer?.backgroundColor.flatMap(NSColor.init(cgColor:))
        if hasBackground {
            XCTAssertTrue(
                layerFill?.isClose(to: OverlayView.labelPillColor(dark: true)) ?? false,
                "live box should show the committed label pill \(message)",
                file: file,
                line: line
            )
        } else {
            XCTAssertNil(layerFill, "no pill while background is off \(message)", file: file, line: line)
        }
        let expectedAppearance: NSAppearance.Name =
            AnnotationTextEditorContrast.usesLightEditor(for: displayedColor) ? .aqua : .darkAqua
        XCTAssertEqual(
            field.appearance?.bestMatch(from: [.aqua, .darkAqua]),
            expectedAppearance,
            "appearance \(message)",
            file: file,
            line: line
        )
    }

    /// The native editor never paints its own fill, so it cannot hide or recolor the pill.
    private func assertEditorContrast(
        _ editor: NSText,
        displayedColor: NSColor,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertFalse(editor.drawsBackground, "editor must stay transparent", file: file, line: line)
        XCTAssertTrue(
            editor.textColor?.isClose(to: displayedColor) ?? false,
            "editor text \(displayedColor)",
            file: file,
            line: line
        )
        let expectedAppearance: NSAppearance.Name =
            AnnotationTextEditorContrast.usesLightEditor(for: displayedColor) ? .aqua : .darkAqua
        let editorAppearance =
            editor.appearance?.bestMatch(from: [.aqua, .darkAqua])
            ?? editor.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua])
        XCTAssertEqual(editorAppearance, expectedAppearance, file: file, line: line)
        if let textView = editor as? NSTextView {
            XCTAssertTrue(
                textView.insertionPointColor.isClose(to: displayedColor),
                "caret should match annotation color",
                file: file,
                line: line
            )
            XCTAssertEqual(
                textView.selectedTextAttributes[.backgroundColor] as? NSColor,
                NSColor.selectedTextBackgroundColor,
                "Selection must use the system highlight background",
                file: file,
                line: line
            )
            XCTAssertEqual(
                textView.selectedTextAttributes[.foregroundColor] as? NSColor,
                NSColor.selectedTextColor,
                "Selection foreground must match the system highlight background",
                file: file,
                line: line
            )
        } else {
            XCTFail("Field editor should be an NSTextView", file: file, line: line)
        }
    }
}
