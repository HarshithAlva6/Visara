/// BuiltInProvider is the zero-config fallback that works on every device.
///
/// No AI. No API keys. No internet. No cost.
/// Uses NSDataDetector — Apple's built-in structured text detector.
/// Returns basic entities: URLs, phones, emails, dates, addresses.
///
/// LEARNING — Why this matters:
/// A library that requires setup has friction. A library that works
/// the moment you install it gets adopted. BuiltInProvider is what
/// makes Visara a zero-friction library. Developers can always
/// upgrade to AI providers later — but they get value immediately.
final class BuiltInProvider: ExtractionProvider {

    var name: String { "Built-in (NSDataDetector)" }

    /// Always available — works on iOS 13+, no configuration needed
    var isAvailable: Bool { true }

    func extract(from text: String) async throws -> [VisaraEntity] {
        var entities: [VisaraEntity] = []

        // Detect structured data types
        let types: NSTextCheckingResult.CheckingType = [
            .phoneNumber,
            .link,
            .date,
            .address
        ]

        guard let detector = try? NSDataDetector(types: types.rawValue) else {
            return entities
        }

        let range = NSRange(text.startIndex..., in: text)
        let matches = detector.matches(in: text, options: [], range: range)

        for match in matches {
            guard let swiftRange = Range(match.range, in: text) else { continue }
            let value = String(text[swiftRange])

            let entityType: EntityType
            switch match.resultType {
            case .phoneNumber: entityType = .phone
            case .link:        entityType = .url
            case .date:        entityType = .date
            case .address:     entityType = .address
            default:           continue
            }

            entities.append(VisaraEntity(
                type: entityType,
                value: value,
                confidence: 1.0,
                range: swiftRange
            ))
        }

        // Additionally detect emails using a simple pattern
        // NSDataDetector catches http/https links but can miss plain emails
        entities += detectEmails(in: text)

        return entities
    }

    // MARK: - Email detection

    private func detectEmails(in text: String) -> [VisaraEntity] {
        // LEARNING — NSRegularExpression:
        // When NSDataDetector doesn't cover a pattern, we use regex.
        // This pattern matches standard email formats.
        let pattern = "[A-Z0-9a-z._%+\\-]+@[A-Za-z0-9.\\-]+\\.[A-Za-z]{2,}"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }

        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, range: range)

        return matches.compactMap { match -> VisaraEntity? in
            guard let swiftRange = Range(match.range, in: text) else { return nil }
            return VisaraEntity(
                type: .email,
                value: String(text[swiftRange]),
                confidence: 0.95,
                range: swiftRange
            )
        }
    }
}
