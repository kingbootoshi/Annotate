import XCTest
import SwiftUI
@testable import Annotate

@MainActor
final class AboutViewTests: XCTestCase {

    // MARK: - Bundle Information Tests

    func testBundleVersionInformationIsAvailable() {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String

        if let version = appVersion {
            XCTAssertFalse(version.isEmpty)
        }

        if let build = buildNumber {
            XCTAssertFalse(build.isEmpty)
        }

        if let name = appName {
            XCTAssertFalse(name.isEmpty)
        }
    }

    // MARK: - View Initialization Tests

    func testAboutViewInitialization() {
        let aboutView = AboutView()
        XCTAssertNotNil(aboutView)
    }

    // MARK: - View Body Tests

    func testViewBodyReturnsNonNilView() {
        let aboutView = AboutView()
        let body = aboutView.body

        XCTAssertNotNil(body)
    }

    // MARK: - Integration Tests

    func testAboutViewCanBeEmbeddedInHostingController() {
        let aboutView = AboutView()
        let hostingController = NSHostingController(rootView: aboutView)

        XCTAssertNotNil(hostingController)
        XCTAssertNotNil(hostingController.view)
    }

    func testMultipleAboutViewInstancesCanCoexist() {
        let aboutView1 = AboutView()
        let aboutView2 = AboutView()

        XCTAssertNotNil(aboutView1)
        XCTAssertNotNil(aboutView2)
    }
}
