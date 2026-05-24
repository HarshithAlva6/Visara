/// ExtractionPipeline selects and runs the best available AI provider.
///
/// It reads the config, checks device eligibility, and falls back
/// gracefully through the provider chain until it finds one that works.
///
/// LEARNING — Dependency Inversion Principle (SOLID):
/// This pipeline depends on the ExtractionProvider PROTOCOL,
/// not on any specific provider class.
/// It doesn't know or care whether it's running Claude or Gemini —
/// it just calls .extract() and gets back [VisaraEntity].
/// Swap a provider, this file never changes.
///
/// LEARNING — Fallback chain pattern:
/// This is a common resilience pattern in production systems.
/// Try the best option. If unavailable, try the next. And so on.
/// The app always gets a result — it just varies in richness.
final class ExtractionPipeline {

    // MARK: - Properties
    private let config: VisaraConfig
    private var selectedProvider: ExtractionProvider?

    /// The type of provider that actually ran — reported in VisaraMetadata
    var activeProviderType: VisaraMetadata.ProviderType = .builtIn

    // MARK: - Init
    init(config: VisaraConfig) {
        self.config = config
        self.selectedProvider = resolveProvider()
    }

    // MARK: - Extraction

    /// Routes raw OCR text to the best available provider.
    func extract(from text: String) async throws -> [VisaraEntity] {
        guard let provider = selectedProvider else {
            throw VisaraError.noProviderAvailable
        }
        return try await provider.extract(from: text)
    }

    // MARK: - Provider Resolution

    /// Selects the best provider based on config and device capability.
    ///
    /// LEARNING — Guard statements:
    /// `guard` is Swift's way of handling early exits cleanly.
    /// "If this condition isn't met, leave." Keeps code flat and readable
    /// instead of deeply nested if/else chains.
    private func resolveProvider() -> ExtractionProvider {
        switch config.provider {

        case .auto:
            return resolveAutoProvider()

        case .foundationModels:
            let provider = FoundationModelsProvider()
            guard provider.isAvailable else {
                // Developer asked for Foundation Models but device isn't eligible
                // Fall back gracefully rather than crashing
                return resolveAutoProvider()
            }
            activeProviderType = .foundationModels
            return provider

        case .claude:
            guard let key = config.claudeAPIKey else {
                // No key provided — fall back to built-in rather than crash
                activeProviderType = .builtIn
                return BuiltInProvider()
            }
            activeProviderType = .claude
            return ClaudeProvider(apiKey: key)

        case .gemini:
            guard let key = config.geminiAPIKey else {
                activeProviderType = .builtIn
                return BuiltInProvider()
            }
            activeProviderType = .gemini
            return GeminiProvider(apiKey: key)

        case .builtIn:
            activeProviderType = .builtIn
            return BuiltInProvider()
        }
    }

    /// Auto mode — tries each provider in order of preference.
    ///
    /// Priority:
    /// 1. Foundation Models — free, private, on-device (iOS 26+)
    /// 2. Claude — if API key provided
    /// 3. Gemini — if API key provided
    /// 4. Built-in — always available, zero cost, basic results
    private func resolveAutoProvider() -> ExtractionProvider {

        // Try Foundation Models first (free, private, fast)
        let foundationProvider = FoundationModelsProvider()
        if foundationProvider.isAvailable {
            activeProviderType = .foundationModels
            return foundationProvider
        }

        // Try Claude if an API key was provided
        if let claudeKey = config.claudeAPIKey {
            activeProviderType = .claude
            return ClaudeProvider(apiKey: claudeKey)
        }

        // Try Gemini if an API key was provided
        if let geminiKey = config.geminiAPIKey {
            activeProviderType = .gemini
            return GeminiProvider(apiKey: geminiKey)
        }

        // Always available fallback — zero config, zero cost
        activeProviderType = .builtIn
        return BuiltInProvider()
    }
}
