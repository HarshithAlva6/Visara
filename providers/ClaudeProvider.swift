import Foundation

/// ClaudeProvider calls Anthropic's Claude API to extract structured entities.
///
/// Used as a fallback when Foundation Models is unavailable.
/// Requires a Claude API key provided via VisaraConfig.
/// Recommended model: claude-haiku (fast, cheap, accurate for extraction)
///
/// LEARNING — URLSession:
/// URLSession is Apple's built-in HTTP networking library.
/// We use it instead of third-party libraries (like Alamofire)
/// to keep Visara dependency-free. Every iOS app has URLSession.
///
/// LEARNING — Codable:
/// Swift's Codable protocol lets us map JSON directly to Swift structs.
/// We define what the API response looks like as a struct,
/// and Swift handles the JSON parsing automatically.
final class ClaudeProvider: ExtractionProvider {

    var name: String { "Claude (Anthropic)" }
    var isAvailable: Bool { !apiKey.isEmpty }

    private let apiKey: String
    private let model = "claude-haiku-4-5"
    private let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func extract(from text: String) async throws -> [VisaraEntity] {
        let requestBody = buildRequest(for: text)

        // LEARNING — URLRequest:
        // We build the HTTP request manually — method, headers, body.
        // Anthropic's API requires specific headers for authentication.
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONEncoder().encode(requestBody)

        // LEARNING — URLSession async/await:
        // data(for:) is the modern async version of URLSession dataTask.
        // We get back (Data, URLResponse) directly — no callbacks needed.
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw VisaraError.extractionFailed("Claude API returned non-200 status")
        }

        // Parse the response and extract entities
        let claudeResponse = try JSONDecoder().decode(ClaudeResponse.self, from: data)
        guard let content = claudeResponse.content.first?.text else {
            throw VisaraError.extractionFailed("Empty response from Claude")
        }

        return parseEntities(from: content)
    }

    // MARK: - Request building

    private func buildRequest(for text: String) -> ClaudeRequest {
        ClaudeRequest(
            model: model,
            maxTokens: 512,
            messages: [
                ClaudeMessage(
                    role: "user",
                    content: buildPrompt(for: text)
                )
            ]
        )
    }

    /// Prompt engineered for fast, structured extraction.
    /// Short prompt = fewer input tokens = lower cost per scan.
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
        // Extract JSON from the response (Claude may wrap it in markdown)
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

// MARK: - Codable models for Claude API

/// LEARNING — Codable structs:
/// These match the exact JSON shape the Claude API expects and returns.
/// `CodingKeys` lets us rename fields when Swift names differ from JSON names.

private struct ClaudeRequest: Encodable {
    let model: String
    let maxTokens: Int
    let messages: [ClaudeMessage]
    enum CodingKeys: String, CodingKey {
        case model
        case maxTokens = "max_tokens"
        case messages
    }
}

private struct ClaudeMessage: Encodable {
    let role: String
    let content: String
}

private struct ClaudeResponse: Decodable {
    let content: [ClaudeContent]
}

private struct ClaudeContent: Decodable {
    let text: String
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
