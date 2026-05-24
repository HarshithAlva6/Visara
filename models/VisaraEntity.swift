/// VisaraEntity represents a single piece of structured information
/// detected within scanned text.
///
/// Generic and language-agnostic — the value is always a plain String
/// so any consuming platform (Swift, JavaScript, Python) can use it
/// without needing to know about Swift-specific types.
public struct VisaraEntity {

    /// What kind of information this is
    public let type: EntityType

    /// The raw detected value as a string
    /// Example: "512-555-0123", "nike.com", "$15.00"
    public let value: String

    /// How confident the extraction engine is — 0.0 to 1.0
    /// 1.0 = certain, 0.0 = uncertain
    public let confidence: Double

    /// Where in the original raw text this entity was found
    /// Useful for highlighting in a UI
    public let range: Range<String.Index>?

    public init(
        type: EntityType,
        value: String,
        confidence: Double,
        range: Range<String.Index>? = nil
    ) {
        self.type = type
        self.value = value
        self.confidence = confidence
        self.range = range
    }
}
