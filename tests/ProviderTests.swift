import XCTest
@testable import Visara

/// Tests for Visara's extraction providers.
///
/// LEARNING — Testing async functions:
/// Swift Testing and XCTest both support async test functions.
/// Just mark your test `async` and use `await` — XCTest handles the rest.
/// No completion handlers, no expectations needed for simple async tests.
///
/// LEARNING — What to test in providers:
/// We test the BuiltInProvider directly since it has no external dependencies.
/// We do NOT test ClaudeProvider or GeminiProvider with real API calls —
/// that would be an integration test, not a unit test.
/// For Claude/Gemini we verify behaviour using the MockSuccessProvider.
final class ProviderTests: XCTestCase {

    // MARK: - BuiltInProvider Tests

    func test_builtInProvider_isAlwaysAvailable() {
        // Given / When
        let provider = BuiltInProvider()

        // Then — must always be true, no matter the device
        XCTAssertTrue(provider.isAvailable)
    }

    func test_builtInProvider_detectsURLs() async throws {
        // Given
        let provider = BuiltInProvider()
        let text = "Visit us at https://nike.com for more info"

        // When
        let entities = try await provider.extract(from: text)

        // Then
        let urls = entities.filter { $0.type == .url }
        XCTAssertFalse(urls.isEmpty, "Should detect at least one URL")
        XCTAssertTrue(urls.contains { $0.value.contains("nike.com") })
    }

    func test_builtInProvider_detectsPhoneNumbers() async throws {
        // Given
        let provider = BuiltInProvider()
        let text = "Call us at 512-555-0123 anytime"

        // When
        let entities = try await provider.extract(from: text)

        // Then
        let phones = entities.filter { $0.type == .phone }
        XCTAssertFalse(phones.isEmpty, "Should detect phone number")
        XCTAssertTrue(phones.contains { $0.value.contains("512") })
    }

    func test_builtInProvider_detectsEmails() async throws {
        // Given
        let provider = BuiltInProvider()
        let text = "Email us at hello@visara.dev for support"

        // When
        let entities = try await provider.extract(from: text)

        // Then
        let emails = entities.filter { $0.type == .email }
        XCTAssertFalse(emails.isEmpty, "Should detect email address")
        XCTAssertTrue(emails.contains { $0.value == "hello@visara.dev" })
    }

    func test_builtInProvider_detectsDates() async throws {
        // Given
        let provider = BuiltInProvider()
        let text = "Join us on June 14th 2026 for the event"

        // When
        let entities = try await provider.extract(from: text)

        // Then
        let dates = entities.filter { $0.type == .date }
        XCTAssertFalse(dates.isEmpty, "Should detect date")
    }

    func test_builtInProvider_emptyText_returnsEmptyEntities() async throws {
        // Given
        let provider = BuiltInProvider()

        // When
        let entities = try await provider.extract(from: TestFixtures.emptyText)

        // Then
        XCTAssertTrue(entities.isEmpty, "No entities should be found in plain text")
    }

    func test_builtInProvider_multipleEntities_detectsAll() async throws {
        // Given
        let provider = BuiltInProvider()

        // When
        let entities = try await provider.extract(from: TestFixtures.simpleText)

        // Then — should find both URL and phone
        let types = entities.map { $0.type }
        XCTAssertTrue(types.contains(.url))
        XCTAssertTrue(types.contains(.phone))
    }

    func test_builtInProvider_allEntitiesHaveValidConfidence() async throws {
        // Given
        let provider = BuiltInProvider()

        // When
        let entities = try await provider.extract(from: TestFixtures.eventFlyerText)

        // Then — confidence must always be between 0 and 1
        for entity in entities {
            XCTAssertGreaterThanOrEqual(entity.confidence, 0.0,
                "Confidence below 0 for entity: \(entity.value)")
            XCTAssertLessThanOrEqual(entity.confidence, 1.0,
                "Confidence above 1 for entity: \(entity.value)")
        }
    }

    func test_builtInProvider_detectsMultipleEmails() async throws {
        let provider = BuiltInProvider()
        let text = "Contact alice@example.com or bob@example.com for info"

        let entities = try await provider.extract(from: text)

        let emails = entities.filter { $0.type == .email }
        XCTAssertEqual(emails.count, 2)
        XCTAssertTrue(emails.contains { $0.value == "alice@example.com" })
        XCTAssertTrue(emails.contains { $0.value == "bob@example.com" })
    }

    func test_builtInProvider_doesNotDetectPrices() async throws {
        // NSDataDetector has no price type — this is a known limitation.
        // AI providers (Claude, Gemini, Foundation Models) cover prices.
        let provider = BuiltInProvider()
        let text = "Tickets: $15 presale / $25 door"

        let entities = try await provider.extract(from: text)

        let prices = entities.filter { $0.type == .price }
        XCTAssertTrue(prices.isEmpty, "BuiltInProvider does not detect prices — use an AI provider for that")
    }

    func test_builtInProvider_bareURLNotDetected_httpsURLDetected() async throws {
        // NSDataDetector reliably detects full https:// URLs.
        // Bare domains like "nike.com" may or may not be detected depending on iOS version.
        let provider = BuiltInProvider()
        let text = "Visit https://nike.com for details"

        let entities = try await provider.extract(from: text)

        let urls = entities.filter { $0.type == .url }
        XCTAssertFalse(urls.isEmpty, "https:// URL must be detected")
        XCTAssertTrue(urls.contains { $0.value.contains("nike.com") })
    }

    // MARK: - ExtractionProvider Protocol Tests (using mocks)

    func test_mockSuccessProvider_returnsPresetEntities() async throws {
        // Given
        let provider = MockSuccessProvider()
        provider.entitiesToReturn = TestFixtures.eventFlyerEntities

        // When
        let entities = try await provider.extract(from: "any text")

        // Then
        XCTAssertEqual(entities.count, TestFixtures.eventFlyerEntities.count)
        XCTAssertEqual(provider.extractCallCount, 1)
    }

    func test_mockFailureProvider_throwsExpectedError() async {
        // Given
        let provider = MockFailureProvider()
        provider.errorToThrow = .extractionFailed("Test error")

        // When / Then
        // LEARNING — async throws testing:
        // We use do/catch to verify that the right error is thrown.
        do {
            _ = try await provider.extract(from: "any text")
            XCTFail("Expected error to be thrown")
        } catch VisaraError.extractionFailed(let message) {
            XCTAssertEqual(message, "Test error")
        } catch {
            XCTFail("Wrong error type thrown: \(error)")
        }
    }

    func test_mockUnavailableProvider_isNotAvailable() {
        // Given / When
        let provider = MockUnavailableProvider()

        // Then
        XCTAssertFalse(provider.isAvailable)
    }
}
