import Foundation
@testable import Visara

// ─────────────────────────────────────────────
// MARK: - Mock Providers
// ─────────────────────────────────────────────

/// LEARNING — Mocking:
/// A mock is a fake version of a real object used only in tests.
/// Because ExtractionProvider is a protocol, we can create a mock
/// that implements the same interface but returns controlled, predictable data.
/// No network. No API keys. No side effects. Just what we tell it to return.
///
/// This is the direct payoff of the Dependency Inversion Principle (SOLID D):
/// Code that depends on protocols is always testable.
/// Code that depends on concrete classes is much harder to test.

/// A mock provider that succeeds and returns preset entities
final class MockSuccessProvider: ExtractionProvider {
    var name: String { "Mock Success Provider" }
    var isAvailable: Bool { true }

    // We can set exactly what entities this provider returns
    var entitiesToReturn: [VisaraEntity] = []

    // Tracks how many times extract() was called — useful for verifying behaviour
    private(set) var extractCallCount = 0

    func extract(from text: String) async throws -> [VisaraEntity] {
        extractCallCount += 1
        return entitiesToReturn
    }
}

/// A mock provider that always fails — for testing error handling
final class MockFailureProvider: ExtractionProvider {
    var name: String { "Mock Failure Provider" }
    var isAvailable: Bool { true }

    var errorToThrow: VisaraError = .extractionFailed("Mock failure")

    func extract(from text: String) async throws -> [VisaraEntity] {
        throw errorToThrow
    }
}

/// A mock provider that is never available — for testing fallback logic
final class MockUnavailableProvider: ExtractionProvider {
    var name: String { "Mock Unavailable Provider" }
    var isAvailable: Bool { false }  // ← always false

    func extract(from text: String) async throws -> [VisaraEntity] {
        // Should never be called — pipeline should skip unavailable providers
        throw VisaraError.noProviderAvailable
    }
}

// ─────────────────────────────────────────────
// MARK: - Test Fixtures
// ─────────────────────────────────────────────

/// LEARNING — Test Fixtures:
/// Fixtures are reusable test data — shared sample objects
/// that multiple test files can use without duplicating setup.

enum TestFixtures {

    /// Sample raw text from a typical event flyer
    static let eventFlyerText = """
        Summer Rooftop Party
        Saturday June 14th • 8PM - 2AM
        Lustre Pearl East • 1124 Lonely St, Austin TX 78702
        Tickets: $15 presale / $25 door
        Get 20% off with code: EARLY20
        lustrepearl.com/tickets
        Call: 512-555-0123
        @lustrepearleast
        info@lustrepearl.com
        """

    /// Sample entities that would be extracted from the above text
    static let eventFlyerEntities: [VisaraEntity] = [
        VisaraEntity(type: .url, value: "lustrepearl.com/tickets", confidence: 0.95),
        VisaraEntity(type: .phone, value: "512-555-0123", confidence: 0.95),
        VisaraEntity(type: .email, value: "info@lustrepearl.com", confidence: 0.95),
        VisaraEntity(type: .date, value: "Saturday June 14th", confidence: 0.90),
        VisaraEntity(type: .price, value: "$15 presale", confidence: 0.90),
        VisaraEntity(type: .discount, value: "EARLY20", confidence: 0.90),
        VisaraEntity(type: .socialHandle, value: "@lustrepearleast", confidence: 0.90),
        VisaraEntity(type: .address, value: "1124 Lonely St, Austin TX 78702", confidence: 0.85)
    ]

    /// Minimal text with just a URL and phone
    static let simpleText = "Visit nike.com or call 512-555-9999"

    /// Text with no detectable entities
    static let emptyText = "The quick brown fox jumps over the lazy dog"
}
