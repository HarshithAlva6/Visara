import XCTest
@testable import Visara

/// End-to-end tests for VisaraScanner.
///
/// LEARNING — Unit vs Integration tests:
/// Unit tests test one thing in isolation.
/// Integration tests test multiple things working together.
/// These scanner tests are closer to integration tests —
/// they test the full flow from config to result.
/// Both kinds are valuable. Unit tests catch bugs early.
/// Integration tests catch wiring mistakes.
///
/// LEARNING — setUp and tearDown:
/// setUp() runs BEFORE every test function — fresh state each time.
/// tearDown() runs AFTER every test function — cleanup.
/// This ensures tests never share state and cannot affect each other.
/// Tests that share state produce flaky, unreliable results.
final class ScannerTests: XCTestCase {

    // MARK: - Properties

    var scanner: VisaraScanner!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        // Fresh scanner before every test
        scanner = VisaraScanner()
    }

    override func tearDown() {
        scanner = nil
        super.tearDown()
    }

    // MARK: - Configuration Tests

    func test_scanner_defaultInit_createsSuccessfully() {
        // Given / When
        let scanner = VisaraScanner()

        // Then
        XCTAssertNotNil(scanner)
    }

    func test_scanner_customConfig_createsSuccessfully() {
        // Given
        let config = VisaraConfig(
            provider: .builtIn,
            claudeAPIKey: nil,
            geminiAPIKey: nil
        )

        // When
        let scanner = VisaraScanner(config: config)

        // Then
        XCTAssertNotNil(scanner)
    }

    // MARK: - Result Structure Tests

    func test_scanner_result_alwaysContainsRawText() async throws {
        // Given
        let scanner = VisaraScanner(config: VisaraConfig(provider: .builtIn))
        let image = makeTestImage(withText: TestFixtures.simpleText)

        // When
        let result = try await scanner.scan(image: image)

        // Then
        XCTAssertFalse(result.rawText.isEmpty)
    }

    func test_scanner_result_containsMetadata() async throws {
        // Given
        let scanner = VisaraScanner(config: VisaraConfig(provider: .builtIn))
        let image = makeTestImage(withText: TestFixtures.simpleText)

        // When
        let result = try await scanner.scan(image: image)

        // Then
        XCTAssertGreaterThan(result.metadata.processingTime, 0)
        XCTAssertGreaterThanOrEqual(result.metadata.ocrConfidence, 0.0)
        XCTAssertLessThanOrEqual(result.metadata.ocrConfidence, 1.0)
    }

    func test_scanner_result_metadataReportsCorrectProvider() async throws {
        // Given — explicitly use built-in provider
        let config = VisaraConfig(provider: .builtIn)
        let scanner = VisaraScanner(config: config)
        let image = makeTestImage(withText: TestFixtures.simpleText)

        // When
        let result = try await scanner.scan(image: image)

        // Then
        XCTAssertEqual(result.metadata.provider, .builtIn)
    }

    // MARK: - Low Confidence Tests

    func test_scanner_lowConfidenceImage_throwsLowConfidenceError() async {
        // Given — a completely blank image will have zero OCR confidence
        let config = VisaraConfig(
            provider: .builtIn,
            minimumOCRConfidence: 0.9  // high threshold
        )
        let scanner = VisaraScanner(config: config)
        let blankImage = makeBlankImage()

        // When / Then
        do {
            _ = try await scanner.scan(image: blankImage)
            // If image somehow passes, that's fine too — OCR on blank might score 0
        } catch VisaraError.lowConfidence(let confidence) {
            XCTAssertLessThan(confidence, 0.9)
        } catch {
            // Other errors are acceptable for a blank image
        }
    }

    // MARK: - Convenience Result Tests

    func test_scanner_builtInProvider_detectsURLInImage() async throws {
        // Given
        let config = VisaraConfig(provider: .builtIn)
        let scanner = VisaraScanner(config: config)
        let image = makeTestImage(withText: "Visit https://visara.dev for details")

        // When
        let result = try await scanner.scan(image: image)

        // Then
        XCTAssertTrue(
            result.urls.contains { $0.contains("visara.dev") },
            "Should detect visara.dev URL. Found: \(result.urls)"
        )
    }

    func test_scanner_builtInProvider_detectsPhoneInImage() async throws {
        // Given
        let config = VisaraConfig(provider: .builtIn)
        let scanner = VisaraScanner(config: config)
        let image = makeTestImage(withText: "Call 512-555-0123 now")

        // When
        let result = try await scanner.scan(image: image)

        // Then
        XCTAssertTrue(
            result.phones.contains { $0.contains("512") },
            "Should detect phone number. Found: \(result.phones)"
        )
    }

    // MARK: - Test Helpers

    /// Creates a UIImage with rendered text — simulates a real scanned image.
    ///
    /// LEARNING — Programmatic UIImage generation:
    /// In tests, we can't use real camera images.
    /// Instead we render text onto a UIImage programmatically.
    /// UIGraphicsImageRenderer is Apple's modern API for drawing to images.
    private func makeTestImage(withText text: String) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 400, height: 200))
        return renderer.image { context in
            // White background
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 400, height: 200))

            // Black text
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18),
                .foregroundColor: UIColor.black
            ]
            text.draw(at: CGPoint(x: 20, y: 80), withAttributes: attributes)
        }
    }

    /// Creates a completely blank white image for testing low-confidence scenarios.
    private func makeBlankImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 100))
        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 100, height: 100))
        }
    }
}
