import Foundation

/// VisaraConfig controls how the library behaves.
///
/// All fields have sensible defaults — the library works
/// with zero configuration out of the box.
public struct VisaraConfig {

    // MARK: - Provider Selection
    /// Which AI provider to use for extraction.
    /// Defaults to .auto — Visara picks the best available option.
    public var provider: ProviderPreference

    // MARK: - API Keys (optional)
    /// Your Claude API key — only needed if using Claude provider
    public var claudeAPIKey: String?

    /// Your Gemini API key — only needed if using Gemini provider
    public var geminiAPIKey: String?

    // MARK: - Behaviour
    /// Minimum OCR confidence required to proceed with extraction.
    /// Below this threshold, Visara returns an error rather than
    /// low-quality results. Range: 0.0 - 1.0. Default: 0.3
    public var minimumOCRConfidence: Double

    /// Maximum time in seconds to wait for a scan to complete.
    /// Default: 30 seconds
    public var timeout: TimeInterval

    // MARK: - Default config
    /// Zero-config default. Works on every device with no API keys.
    public static let `default` = VisaraConfig(
        provider: .auto,
        claudeAPIKey: nil,
        geminiAPIKey: nil,
        minimumOCRConfidence: 0.3,
        timeout: 30
    )

    public init(
        provider: ProviderPreference = .auto,
        claudeAPIKey: String? = nil,
        geminiAPIKey: String? = nil,
        minimumOCRConfidence: Double = 0.3,
        timeout: TimeInterval = 30
    ) {
        self.provider = provider
        self.claudeAPIKey = claudeAPIKey
        self.geminiAPIKey = geminiAPIKey
        self.minimumOCRConfidence = minimumOCRConfidence
        self.timeout = timeout
    }

    /// How Visara selects an AI provider
    public enum ProviderPreference {
        /// Visara picks the best available option automatically:
        /// Foundation Models → Claude → Gemini → Built-in
        case auto

        /// Force on-device Apple Foundation Models (iOS 26+ only)
        case foundationModels

        /// Force Claude API (requires claudeAPIKey)
        case claude

        /// Force Gemini API (requires geminiAPIKey)
        case gemini

        /// Force zero-config built-in extraction (no AI, always free)
        case builtIn
    }
}
