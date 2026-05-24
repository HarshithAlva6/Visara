import UIKit

/// VisaraScanner is the main entry point for the library.
///
/// This is the only type a consuming app needs to interact with.
/// It coordinates the full pipeline:
/// Image → OCR → Provider Selection → Structured Result
///
/// SOLID — Single Responsibility:
/// VisaraScanner does ONE thing — coordinate the scan pipeline.
/// It does not do OCR (OCREngine does that).
/// It does not do AI extraction (providers do that).
/// It orchestrates. Clean. Testable. Replaceable.
public final class VisaraScanner {

    // MARK: - Dependencies
    private let config: VisaraConfig
    private let ocrEngine: OCREngine
    private let pipeline: ExtractionPipeline

    // MARK: - Initialisation

    /// Zero-config init. Works on every device, no API keys needed.
    public convenience init() {
        self.init(config: .default)
    }

    /// Custom config init — provide API keys or force a provider.
    public init(config: VisaraConfig) {
        self.config = config
        self.ocrEngine = OCREngine()
        self.pipeline = ExtractionPipeline(config: config)
    }

    // MARK: - Public API

    /// Scan a UIImage and return structured data.
    ///
    /// This is the single public function of the entire library.
    /// Everything else exists to support this one call.
    ///
    /// - Parameter image: Any UIImage — camera, photo library, or file
    /// - Returns: VisaraResult containing all detected entities
    /// - Throws: VisaraError if OCR or extraction fails
    ///
    /// Example:
    /// ```swift
    /// let scanner = VisaraScanner()
    /// let result = try await scanner.scan(image: myImage)
    /// print(result.urls)    // ["nike.com"]
    /// print(result.phones)  // ["512-555-0123"]
    /// ```
    public func scan(image: UIImage) async throws -> VisaraResult {
        let startTime = Date()

        // Step 1: Extract raw text from image using Vision OCR
        let ocrOutput = try await ocrEngine.extractText(from: image)

        // Step 2: Reject scans below the confidence threshold
        guard ocrOutput.confidence >= config.minimumOCRConfidence else {
            throw VisaraError.lowConfidence(ocrOutput.confidence)
        }

        // Step 3: Route raw text through the best available provider
        let entities = try await pipeline.extract(from: ocrOutput.text)

        // Step 4: Assemble and return the result
        let processingTime = Date().timeIntervalSince(startTime)
        let metadata = VisaraMetadata(
            provider: pipeline.activeProviderType,
            processingTime: processingTime,
            ocrConfidence: ocrOutput.confidence
        )

        return VisaraResult(
            rawText: ocrOutput.text,
            entities: entities,
            metadata: metadata
        )
    }
}
