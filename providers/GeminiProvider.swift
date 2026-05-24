import Foundation

/// GeminiProvider calls Google's Gemini API to extract structured entities.
///
/// Structurally identical to ClaudeProvider — same protocol, different endpoint.
/// This is the Liskov Substitution Principle in action:
/// ClaudeProvider and GeminiProvider are completely interchangeable
/// from the pipeline's perspective. Same input. Same output. Different internals.
///
/// Uses Gemini Flash — fast and cost-effective for extraction tasks.
/// Has a free tier — ideal for development and low-volume usage.
final class GeminiProvider: ExtractionProvider {

    var name: String { "Gemini (Google)" }
    var isAvailable: Bool { !apiKey.isEmpty }

    private let apiKey: String
    private let model = "gemini-2.0-flash"
    private var endpoint: URL {
        URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)")!
    }

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func extract(from text: String) async throws -> [VisaraEntity] {
        let requestBody = buildRequest(for: text)

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw VisaraError.extractionFailed("Gemini API returned non-200 status")
        }

        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        guard let content = geminiResponse.candidates.first?.content.parts.first?.text else {
            throw VisaraError.extractionFailed("Empty response from Gemini")
        }

        return parseEntities(from: content)
    }

    // MARK: - Request building

    private func buildRequest(for text: String) -> GeminiRequest {
        GeminiRequest(
            contents: [
                GeminiContent(
                    parts: [GeminiPart(text: buildPrompt(for: text))]
                )
            ]
        )
    }

    private func buildPrompt(for text: String) -> String {
        """
        Extract structured data from this text. Return ONLY a JSON object with these keys:
        urls, phones, emails, dates, prices, discounts, socialHandles, addresses.
        Each value is an array of strings. Use empty arrays if nothing found.

        Text: \(text)
        """
    }

    // MARK: - Response parsing

    private func parseEntities(from jsonString: String) -> [VisaraEntity] {
        let cleaned = jsonString
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = cleaned.data(using: .utf8),
              let json = try? JSONDecoder().decode(ExtractedJSON.self, from: data) else {
            return []
        }

        var entities: [VisaraEntity] = []
        entities += json.urls.map { VisaraEntity(type: .url, value: $0, confidence: 0.95) }
        entities += json.phones.map { VisaraEntity(type: .phone, value: $0, confidence: 0.95) }
        entities += json.emails.map { VisaraEntity(type: .email, value: $0, confidence: 0.95) }
        entities += json.dates.map { VisaraEntity(type: .date, value: $0, confidence: 0.90) }
        entities += json.prices.map { VisaraEntity(type: .price, value: $0, confidence: 0.90) }
        entities += json.discounts.map { VisaraEntity(type: .discount, value: $0, confidence: 0.90) }
        entities += json.socialHandles.map { VisaraEntity(type: .socialHandle, value: $0, confidence: 0.90) }
        entities += json.addresses.map { VisaraEntity(type: .address, value: $0, confidence: 0.85) }
        return entities
    }
}

// MARK: - Codable models for Gemini API

private struct GeminiRequest: Encodable {
    let contents: [GeminiContent]
}

private struct GeminiContent: Codable {
    let parts: [GeminiPart]
}

private struct GeminiPart: Codable {
    let text: String
}

private struct GeminiResponse: Decodable {
    let candidates: [GeminiCandidate]
}

private struct GeminiCandidate: Decodable {
    let content: GeminiContent
}

private struct ExtractedJSON: Decodable {
    let urls: [String]
    let phones: [String]
    let emails: [String]
    let dates: [String]
    let prices: [String]
    let discounts: [String]
    let socialHandles: [String]
    let addresses: [String]
}
