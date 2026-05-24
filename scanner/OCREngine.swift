import UIKit
import Vision

/// OCREngine reads raw text from an image using Apple's Vision framework.
///
/// It also runs NSDataDetector as a free post-processing pass —
/// extracting phones, URLs, dates and addresses with zero API cost.
///
/// LEARNING — Vision Framework:
/// Vision is Apple's on-device computer vision library.
/// VNRecognizeTextRequest is its OCR (text recognition) tool.
/// It runs entirely on the device — no internet, no cost, iOS 13+.
///
/// LEARNING — NSDataDetector:
/// A built-in Apple class that finds structured data in text.
/// Think of it as a smart regex engine that already knows what
/// a phone number, URL, address, and date look like.
/// Free. Fast. Works offline. No AI needed.

// MARK: - Output type from OCR

/// Raw output from the OCR pass — text and how confident we are
struct OCROutput {
    let text: String
    let confidence: Double
    let basicEntities: [VisaraEntity]  // NSDataDetector results
}

// MARK: - Engine

final class OCREngine {

    /// Extracts raw text and basic entities from a UIImage.
    ///
    /// LEARNING — async/await with callbacks:
    /// Vision framework uses the older callback/closure style internally.
    /// We wrap it in a Swift continuation to expose it as async/await.
    /// This is a common pattern when bridging old Apple APIs to modern Swift.
    func extractText(from image: UIImage) async throws -> OCROutput {
        guard let cgImage = image.cgImage else {
            throw VisaraError.ocrFailed("Could not read image data")
        }

        // Wrap the Vision callback API in async/await using a continuation
        // LEARNING — withCheckedThrowingContinuation:
        // This is how you convert a callback-based function into async/await.
        // `resume(returning:)` is the "resolve" of the async operation.
        // `resume(throwing:)` is the "reject".
        let recognizedText = try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<[(String, Float)], Error>) in

            // Create the text recognition request
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: VisaraError.ocrFailed(error.localizedDescription))
                    return
                }

                // Extract recognized text observations
                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let textAndConfidence = observations.compactMap { observation -> (String, Float)? in
                    guard let candidate = observation.topCandidates(1).first else { return nil }
                    return (candidate.string, candidate.confidence)
                }

                continuation.resume(returning: textAndConfidence)
            }

            // Accurate is slower but gives better results for small text on signs/flyers
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: VisaraError.ocrFailed(error.localizedDescription))
            }
        }

        // Combine all text pieces into one string
        let fullText = recognizedText.map { $0.0 }.joined(separator: "\n")

        // Average confidence across all recognized segments
        let avgConfidence = recognizedText.isEmpty ? 0.0 :
            Double(recognizedText.map { $0.1 }.reduce(0, +)) / Double(recognizedText.count)

        // Run NSDataDetector on the extracted text for free basic entity extraction
        let basicEntities = extractBasicEntities(from: fullText)

        return OCROutput(
            text: fullText,
            confidence: avgConfidence,
            basicEntities: basicEntities
        )
    }

    // MARK: - NSDataDetector (zero-config, zero-cost extraction)

    /// Extracts phones, URLs, dates and addresses using Apple's built-in detector.
    ///
    /// LEARNING — NSDataDetector:
    /// We combine multiple detector types using bitwise OR (|).
    /// Each type is a different "sensor" that looks for a specific pattern.
    /// This is much faster and more accurate than writing regex yourself.
    private func extractBasicEntities(from text: String) -> [VisaraEntity] {
        var entities: [VisaraEntity] = []

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
            guard let range = Range(match.range, in: text) else { continue }
            let value = String(text[range])

            // Map NSDataDetector result type to our EntityType
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
                confidence: 1.0,  // NSDataDetector is rule-based — always certain
                range: range
            ))
        }

        return entities
    }
}
