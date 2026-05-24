/// FoundationModelsProvider uses Apple's on-device LLM (iOS 26+)
/// to extract rich structured entities from text.
///
/// Zero cost. Zero internet. Fully private. ~3B parameter model.
/// Requires iPhone 15 Pro+ or any iPhone 16/17.
///
/// LEARNING — Apple Foundation Models:
/// iOS 26 ships with a ~3B parameter language model on every
/// eligible device. The Foundation Models framework gives developers
/// direct access to it. No API key. No usage cost. No data leaves
/// the device. It's the same model that powers Apple Intelligence.
///
/// LEARNING — @Generable macro:
/// Instead of asking the model to return JSON and then parsing it
/// (error-prone), @Generable tells the model to produce output
/// that directly maps to your Swift struct. Type-safe. No parsing.
/// The model is constrained at the token level to produce valid output.

// MARK: - Structured output type for Foundation Models

/// The shape of data we ask Foundation Models to extract.
/// @Generable makes this directly producible by the on-device LLM.
///
/// NOTE: Foundation Models framework is iOS 26+
/// We use #available checks to compile conditionally.
@available(iOS 26.0, *)
// @Generable  ← Uncomment when building on Xcode with iOS 26 SDK
struct ExtractedContent {
    var urls: [String]
    var phones: [String]
    var emails: [String]
    var dates: [String]
    var prices: [String]
    var discounts: [String]
    var socialHandles: [String]
    var addresses: [String]
    var title: String?
    var summary: String?
}

// MARK: - Provider

final class FoundationModelsProvider: ExtractionProvider {

    var name: String { "Apple Foundation Models (on-device)" }

    /// Only available on iOS 26+ with Apple Intelligence enabled
    var isAvailable: Bool {
        if #available(iOS 26.0, *) {
            // LanguageModelSession.isAvailable checks Apple Intelligence eligibility
            // Uncomment when building with iOS 26 SDK:
            // return LanguageModelSession.isAvailable
            return false // placeholder until iOS 26 SDK
        }
        return false
    }

    func extract(from text: String) async throws -> [VisaraEntity] {
        guard #available(iOS 26.0, *) else {
            throw VisaraError.noProviderAvailable
        }

        // LEARNING — LanguageModelSession:
        // This is Apple's interface to the on-device LLM.
        // Creating a session is lightweight — the model is already
        // loaded on the device as part of Apple Intelligence.
        //
        // When iOS 26 SDK is available, replace this with:
        //
        // let session = LanguageModelSession()
        // let result = try await session.respond(
        //     to: buildPrompt(for: text),
        //     generating: ExtractedContent.self
        // )
        // return mapToEntities(result)

        // Placeholder until iOS 26 SDK is integrated
        throw VisaraError.noProviderAvailable
    }

    // MARK: - Prompt Engineering

    /// Builds the instruction for the on-device model.
    ///
    /// LEARNING — Prompt Engineering:
    /// How you ask the model matters as much as which model you use.
    /// We are explicit, structured, and give examples.
    /// Short prompts = fewer tokens = faster response on-device.
    private func buildPrompt(for text: String) -> String {
        """
        Extract all structured information from the following text.
        Find: URLs, phone numbers, emails, dates, prices, discount codes,
        social media handles (@username), and physical addresses.
        If a URL is implied (e.g. "find us at Nike dot com") normalise it.
        Text to analyse:
        \(text)
        """
    }

    // MARK: - Result mapping

    /// Maps the @Generable struct back to [VisaraEntity]
    @available(iOS 26.0, *)
    private func mapToEntities(_ content: ExtractedContent) -> [VisaraEntity] {
        var entities: [VisaraEntity] = []

        entities += content.urls.map { VisaraEntity(type: .url, value: $0, confidence: 0.95) }
        entities += content.phones.map { VisaraEntity(type: .phone, value: $0, confidence: 0.95) }
        entities += content.emails.map { VisaraEntity(type: .email, value: $0, confidence: 0.95) }
        entities += content.dates.map { VisaraEntity(type: .date, value: $0, confidence: 0.90) }
        entities += content.prices.map { VisaraEntity(type: .price, value: $0, confidence: 0.90) }
        entities += content.discounts.map { VisaraEntity(type: .discount, value: $0, confidence: 0.90) }
        entities += content.socialHandles.map { VisaraEntity(type: .socialHandle, value: $0, confidence: 0.90) }
        entities += content.addresses.map { VisaraEntity(type: .address, value: $0, confidence: 0.85) }

        return entities
    }
}
