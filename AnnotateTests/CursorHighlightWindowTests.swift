import XCTest

@testable import Annotate

@MainActor
final class CursorHighlightWindowTests: XCTestCase {
    func testAnimationLoopUsesWindowDisplayLink() {
        let window = CursorHighlightWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        window.startAnimationLoop()

        XCTAssertNotNil(window.animationDisplayLink)

        window.stopAnimationLoop()

        XCTAssertNil(window.animationDisplayLink)
    }
}
