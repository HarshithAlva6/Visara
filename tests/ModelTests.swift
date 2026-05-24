import XCTest
@testable import Visara

/// Tests for Visara's model layer — VisaraResult, VisaraEntity, EntityType, VisaraConfig.
///
/// LEARNING — @testable import:
/// Normally, `internal` Swift types are invisible outside their module.
/// @testable import gives test files access to internal types and functions.
/// This lets us test implementation details without making everything public.
///
/// LEARNING — XCTestCase:
/// Every test class inherits from XCTestCase.
/// Every function that starts with `test` is automatically run as a test.
/// No registration needed — XCTest finds them by naming convention.
final class ModelTests: XCTestCase {

    // MARK: - EntityType Tests

    /// LEARNING — Given / When / Then:
    /// The best test structure has three parts:
    /// Given — set up the conditions
    /// When  — perform the action
    /// Then  — assert the expected result
    /// This makes tests readable like plain English sentences.

    func test_entityType_custom_storesAssociatedValue() {
        // Given
        let customType = EntityType.custom("eventName")

        // When / Then
        if case .custom(let value) = customType {
            XCTAssertEqual(value, "eventName")
        } else {
            XCTFail("Expected .custom case")
        }
    }

    func test_entityType_equality() {
        // Same types should be equal
        XCTAssertEqual(EntityType.phone, EntityType.phone)
        XCTAssertEqual(EntityType.custom("a"), EntityType.custom("a"))

        // Different types should not be equal
        XCTAssertNotEqual(EntityType.phone, EntityType.email)
        XCTAssertNotEqual(EntityType.custom("a"), EntityType.custom("b"))
    }

    // MARK: - VisaraEntity Tests

    func test_visaraEntity_storesAllProperties() {
        // Given / When
        let entity = VisaraEntity(
            type: .url,
            value: "nike.com",
            confidence: 0.95
        )

        // Then
        XCTAssertEqual(entity.type, .url)
        XCTAssertEqual(entity.value, "nike.com")
        XCTAssertEqual(entity.confidence, 0.95, accuracy: 0.001)
        XCTAssertNil(entity.range)  // range is optional
    }

    func test_visaraEntity_confidenceRange() {
        // Confidence should be between 0.0 and 1.0
        let entity = VisaraEntity(type: .phone, value: "512-555-0123", confidence: 0.87)
        XCTAssertGreaterThanOrEqual(entity.confidence, 0.0)
        XCTAssertLessThanOrEqual(entity.confidence, 1.0)
    }

    // MARK: - VisaraResult Tests

    func test_visaraResult_convenienceAccessors_returnCorrectEntities() {
        // Given
        let entities = TestFixtures.eventFlyerEntities
        let metadata = VisaraMetadata(provider: .builtIn, processingTime: 0.5, ocrConfidence: 0.9)
        let result = VisaraResult(
            rawText: TestFixtures.eventFlyerText,
            entities: entities,
            metadata: metadata
        )

        // Then — convenience accessors filter correctly
        XCTAssertTrue(result.urls.contains("lustrepearl.com/tickets"))
        XCTAssertTrue(result.phones.contains("512-555-0123"))
        XCTAssertTrue(result.emails.contains("info@lustrepearl.com"))
        XCTAssertTrue(result.discounts.contains("EARLY20"))
        XCTAssertTrue(result.socialHandles.contains("@lustrepearleast"))
    }

    func test_visaraResult_entitiesOfType_filtersCorrectly() {
        // Given
        let entities = TestFixtures.eventFlyerEntities
        let metadata = VisaraMetadata(provider: .builtIn, processingTime: 0.5, ocrConfidence: 0.9)
        let result = VisaraResult(rawText: "", entities: entities, metadata: metadata)

        // When
        let urlEntities = result.entities(ofType: .url)
        let phoneEntities = result.entities(ofType: .phone)

        // Then
        XCTAssertEqual(urlEntities.count, 1)
        XCTAssertEqual(phoneEntities.count, 1)
        XCTAssertTrue(urlEntities.allSatisfy { $0.type == .url })
    }

    func test_visaraResult_emptyEntities_returnsEmptyArrays() {
        // Given
        let metadata = VisaraMetadata(provider: .builtIn, processingTime: 0.1, ocrConfidence: 0.8)
        let result = VisaraResult(rawText: "some text", entities: [], metadata: metadata)

        // Then — all convenience arrays should be empty
        XCTAssertTrue(result.urls.isEmpty)
        XCTAssertTrue(result.phones.isEmpty)
        XCTAssertTrue(result.emails.isEmpty)
        XCTAssertTrue(result.discounts.isEmpty)
    }

    // MARK: - VisaraConfig Tests

    func test_visaraConfig_default_hasExpectedValues() {
        // Given / When
        let config = VisaraConfig.default

        // Then
        if case .auto = config.provider { } else {
            XCTFail("Default provider should be .auto")
        }
        XCTAssertNil(config.claudeAPIKey)
        XCTAssertNil(config.geminiAPIKey)
        XCTAssertEqual(config.minimumOCRConfidence, 0.3, accuracy: 0.001)
        XCTAssertEqual(config.timeout, 30, accuracy: 0.001)
    }

    func test_visaraConfig_customInit_storesValues() {
        // Given / When
        let config = VisaraConfig(
            provider: .claude,
            claudeAPIKey: "sk-test-key",
            geminiAPIKey: nil,
            minimumOCRConfidence: 0.5,
            timeout: 60
        )

        // Then
        XCTAssertEqual(config.claudeAPIKey, "sk-test-key")
        XCTAssertNil(config.geminiAPIKey)
        XCTAssertEqual(config.minimumOCRConfidence, 0.5, accuracy: 0.001)
        XCTAssertEqual(config.timeout, 60, accuracy: 0.001)
    }
}
