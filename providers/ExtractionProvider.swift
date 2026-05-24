/// ExtractionProvider is the single contract every AI provider must follow.
///
/// This is the core of Visara's extensibility. Any AI backend —
/// on-device, cloud, or custom — implements this one protocol.
/// The rest of the library never needs to change when a new provider
/// is added. This is the Open/Closed Principle from SOLID.
///
/// LEARNING NOTE — Swift Protocols:
/// A protocol in Swift is like a contract or interface.
/// It says "any type that claims to be an ExtractionProvider
/// MUST have this function." It doesn't care HOW it's done —
/// only that it IS done. This lets us swap Claude for Gemini
/// without touching the scanner or the models.
public protocol ExtractionProvider {

    /// A human-readable name for this provider
    /// Example: "Apple Foundation Models", "Claude (Haiku)", "Built-in"
    var name: String { get }

    /// Whether this provider is available on the current device.
    /// Foundation Models returns false on iPhone 14 and older.
    /// Claude returns false if no API key is configured.
    var isAvailable: Bool { get }

    /// Extract structured entities from raw OCR text.
    ///
    /// - Parameter text: The raw text string returned by OCREngine
    /// - Returns: An array of detected VisaraEntity values
    /// - Throws: VisaraError if extraction fails
    ///
    /// LEARNING NOTE — async/await:
    /// The `async` keyword means this function does work in the
    /// background without blocking the main thread (the UI).
    /// `await` tells Swift "pause here until the result is ready,
    /// but don't freeze the app." This replaced the older GCD/callback
    /// pattern and is the modern Swift concurrency standard.
    func extract(from text: String) async throws -> [VisaraEntity]
}

// VisaraError is defined in scanner/VisaraError.swift
