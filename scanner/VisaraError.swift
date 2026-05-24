import Foundation

/// All errors that Visara can throw — typed, descriptive, and catchable.
///
/// LEARNING — Error enums with associated values:
/// Swift errors are just enums that conform to the Error protocol.
/// Associated values let each case carry context about WHY it failed.
/// The caller can pattern match to handle each case differently.
///
/// Example:
/// ```swift
/// do {
///     let result = try await scanner.scan(image: image)
/// } catch VisaraError.lowConfidence(let score) {
///     print("Image too blurry — confidence was \(score)")
/// } catch VisaraError.noProviderAvailable {
///     print("Configure an API key to get richer results")
/// } catch {
///     print("Unexpected error: \(error)")
/// }
/// ```
public enum VisaraError: Error, LocalizedError {

    /// The OCR engine could not read text from the image.
    /// Associated value: the underlying reason as a string.
    case ocrFailed(String)

    /// OCR succeeded but confidence was below the configured threshold.
    /// Associated value: the actual confidence score (0.0 - 1.0).
    case lowConfidence(Double)

    /// No extraction provider is available or configured.
    /// Happens when Foundation Models is unavailable and no API key is set.
    case noProviderAvailable

    /// The provider ran but returned an error.
    /// Associated value: the provider's error message.
    case extractionFailed(String)

    /// The scan exceeded the configured timeout.
    case timeout

    /// A required API key is missing.
    /// Associated value: which provider needs the key.
    case missingAPIKey(String)

    // MARK: - LocalizedError

    /// LEARNING — LocalizedError:
    /// Conforming to LocalizedError lets us provide human-readable
    /// descriptions. These appear in logs, error UI, and debug output.
    public var errorDescription: String? {
        switch self {
        case .ocrFailed(let reason):
            return "OCR failed: \(reason)"
        case .lowConfidence(let score):
            return "Image confidence too low (\(String(format: "%.0f", score * 100))%). Try a clearer image."
        case .noProviderAvailable:
            return "No extraction provider available. Configure an API key or use a device with Apple Intelligence."
        case .extractionFailed(let reason):
            return "Extraction failed: \(reason)"
        case .timeout:
            return "Scan timed out. Check your connection or increase the timeout in VisaraConfig."
        case .missingAPIKey(let provider):
            return "Missing API key for \(provider). Set it via VisaraConfig."
        }
    }
}
