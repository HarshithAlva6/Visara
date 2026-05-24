import ExpoModulesCore
import UIKit

/// VisaraModule is the bridge between Swift and JavaScript.
///
/// It registers Visara with the Expo Modules API, exposes functions
/// that JavaScript can call, and converts Swift types to bridge-safe
/// types that can cross into the JavaScript world.
///
/// LEARNING — Expo Modules API:
/// Expo Modules API is the modern way to write native modules for React Native.
/// It replaces the older Objective-C bridge with a cleaner Swift-first API.
/// Any function defined inside `definition()` becomes callable from JavaScript.
///
/// LEARNING — Data crossing the bridge:
/// Swift structs cannot cross the bridge directly.
/// Everything must be converted to primitive types:
///   String, Int, Double, Bool, [Any], [String: Any]
/// These map directly to JavaScript's string, number, boolean, array, object.
/// We convert VisaraResult → [String: Any] (a dictionary) before returning.
public class VisaraModule: Module {

    // The shared scanner instance — created once, reused across calls
    private var scanner = VisaraScanner()

    public func definition() -> ModuleDefinition {

        // LEARNING — Name:
        // This is how JavaScript finds this module.
        // requireNativeModule('Visara') in TypeScript looks for this name.
        Name("Visara")

        // MARK: - configure()
        // Lets JavaScript pass configuration before scanning.
        // Called once at app startup with API keys and preferences.
        //
        // LEARNING — Function vs AsyncFunction:
        // Function is synchronous — runs immediately, no waiting.
        // AsyncFunction is asynchronous — can do network calls, file reads.
        // configure() is sync because it just stores values in memory.
        Function("configure") { (options: [String: Any]) in
            var config = VisaraConfig()

            if let claudeKey = options["claudeAPIKey"] as? String {
                config.claudeAPIKey = claudeKey
            }
            if let geminiKey = options["geminiAPIKey"] as? String {
                config.geminiAPIKey = geminiKey
            }
            if let providerString = options["provider"] as? String {
                config.provider = self.mapProvider(providerString)
            }
            if let timeout = options["timeout"] as? Double {
                config.timeout = timeout
            }

            // Rebuild scanner with new config
            self.scanner = VisaraScanner(config: config)
        }

        // MARK: - scan()
        // The main function. Takes an image path, returns structured data.
        //
        // LEARNING — AsyncFunction:
        // This is async because it does real work:
        // reading an image, running OCR, calling an API.
        // JavaScript awaits this: const result = await Visara.scan(path)
        AsyncFunction("scan") { (imagePath: String) -> [String: Any] in

            // Convert the file path to a UIImage
            guard let image = self.loadImage(from: imagePath) else {
                throw VisaraModuleError.invalidImagePath(imagePath)
            }

            // Run the full Visara pipeline
            // LEARNING — try await inside AsyncFunction:
            // Expo handles the async/await bridging automatically.
            // If this throws, Expo converts it to a JavaScript Error.
            let result = try await self.scanner.scan(image: image)

            // Convert VisaraResult to a bridge-safe dictionary
            return self.serializeResult(result)
        }
    }

    // MARK: - Private helpers

    /// Loads a UIImage from a file path string.
    ///
    /// React Native passes image paths as file:// URLs or absolute paths.
    /// We handle both formats here.
    private func loadImage(from path: String) -> UIImage? {
        // Handle file:// URL format
        if path.hasPrefix("file://"),
           let url = URL(string: path) {
            return UIImage(contentsOfFile: url.path)
        }
        // Handle absolute path format
        return UIImage(contentsOfFile: path)
    }

    /// Converts a VisaraResult into a bridge-safe dictionary.
    ///
    /// LEARNING — Serialization:
    /// This is where Swift types become JavaScript-readable objects.
    /// Every field must be a type the bridge understands:
    /// String, Double, Bool, [Any], [String: Any]
    private func serializeResult(_ result: VisaraResult) -> [String: Any] {
        return [
            "rawText": result.rawText,
            "entities": result.entities.map { serializeEntity($0) },
            "urls": result.urls,
            "phones": result.phones,
            "emails": result.emails,
            "dates": result.dates,
            "prices": result.prices,
            "discounts": result.discounts,
            "socialHandles": result.socialHandles,
            "addresses": result.addresses,
            "metadata": [
                "provider": result.metadata.provider.rawValue,
                "processingTime": result.metadata.processingTime,
                "ocrConfidence": result.metadata.ocrConfidence
            ]
        ]
    }

    /// Converts a single VisaraEntity to a bridge-safe dictionary.
    private func serializeEntity(_ entity: VisaraEntity) -> [String: Any] {
        return [
            "type": entityTypeString(entity.type),
            "value": entity.value,
            "confidence": entity.confidence
        ]
    }

    /// Converts EntityType enum to a plain string for JavaScript.
    ///
    /// LEARNING — Enums crossing the bridge:
    /// Swift enums cannot cross the bridge.
    /// We convert them to strings — JavaScript uses string comparisons.
    private func entityTypeString(_ type: EntityType) -> String {
        switch type {
        case .phone:         return "phone"
        case .email:         return "email"
        case .url:           return "url"
        case .socialHandle:  return "socialHandle"
        case .date:          return "date"
        case .time:          return "time"
        case .price:         return "price"
        case .discount:      return "discount"
        case .address:       return "address"
        case .custom(let s): return "custom:\(s)"
        }
    }

    /// Maps provider string from JavaScript to VisaraConfig.ProviderPreference
    private func mapProvider(_ string: String) -> VisaraConfig.ProviderPreference {
        switch string {
        case "foundationModels": return .foundationModels
        case "claude":           return .claude
        case "gemini":           return .gemini
        case "builtIn":          return .builtIn
        default:                 return .auto
        }
    }
}

// MARK: - Bridge errors

/// Errors specific to the bridge layer.
/// These become JavaScript Error objects on the JS side.
enum VisaraModuleError: Error {
    case invalidImagePath(String)
}
