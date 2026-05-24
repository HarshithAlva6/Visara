import Foundation

/// VisaraResult is the single output contract for every scan.
///
/// Regardless of which provider ran (on-device AI, Claude, Gemini,
/// or zero-config built-in), the consuming app always receives
/// this same structure. This is the Liskov Substitution Principle
/// in action — swap the provider, the result shape never changes.
public struct VisaraResult {

    // MARK: - Raw Output
    /// The full raw text extracted from the image by OCR
    public let rawText: String

    // MARK: - Structured Entities
    /// All detected entities — links, phones, dates, prices, etc.
    public let entities: [VisaraEntity]

    // MARK: - Metadata
    /// How the scan was processed
    public let metadata: VisaraMetadata

    // MARK: - Convenience accessors
    /// Quick access to entities by type
    public func entities(ofType type: EntityType) -> [VisaraEntity] {
        entities.filter { $0.type == type }
    }

    public var urls: [String]         { entities(ofType: .url).map(\.value) }
    public var phones: [String]       { entities(ofType: .phone).map(\.value) }
    public var emails: [String]       { entities(ofType: .email).map(\.value) }
    public var dates: [String]        { entities(ofType: .date).map(\.value) }
    public var prices: [String]       { entities(ofType: .price).map(\.value) }
    public var discounts: [String]    { entities(ofType: .discount).map(\.value) }
    public var socialHandles: [String] { entities(ofType: .socialHandle).map(\.value) }
    public var addresses: [String]    { entities(ofType: .address).map(\.value) }

    public init(rawText: String, entities: [VisaraEntity], metadata: VisaraMetadata) {
        self.rawText = rawText
        self.entities = entities
        self.metadata = metadata
    }
}

/// Describes how and where the scan was processed
public struct VisaraMetadata {

    /// Which provider performed the AI extraction
    public let provider: ProviderType

    /// Total time taken for the full scan in seconds
    public let processingTime: TimeInterval

    /// OCR confidence score — how clearly the text was read
    public let ocrConfidence: Double

    public enum ProviderType: String {
        case foundationModels = "foundation-models"  // on-device, iOS 26+
        case claude           = "claude"              // Anthropic API
        case gemini           = "gemini"              // Google API
        case builtIn          = "built-in"            // zero-config NSDataDetector
    }

    public init(
        provider: ProviderType,
        processingTime: TimeInterval,
        ocrConfidence: Double
    ) {
        self.provider = provider
        self.processingTime = processingTime
        self.ocrConfidence = ocrConfidence
    }
}
