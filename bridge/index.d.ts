/**
 * Visara — bridge/index.ts
 *
 * The public JavaScript/TypeScript interface for Visara.
 * This is what developers import when they use the library.
 *
 * LEARNING — requireNativeModule:
 * This is Expo's way of loading a native Swift module into JavaScript.
 * It looks for a native module named 'Visara' (matching our Swift Name("Visara"))
 * and gives us a typed interface to call its functions.
 *
 * LEARNING — Why TypeScript types matter here:
 * The bridge is untyped at runtime — it passes plain objects.
 * TypeScript types give developers autocomplete, catch mistakes at
 * compile time, and make the library feel professional and safe to use.
 */
/**
 * The type of entity detected in the scanned image.
 * Mirrors EntityType in Swift — but as a TypeScript union type.
 */
export type EntityType = 'url' | 'phone' | 'email' | 'date' | 'time' | 'price' | 'discount' | 'socialHandle' | 'address' | `custom:${string}`;
/**
 * A single piece of structured information detected in the image.
 */
export interface VisaraEntity {
    /** What kind of information this is */
    type: EntityType;
    /** The raw detected value */
    value: string;
    /** Confidence score — 0.0 to 1.0 */
    confidence: number;
}
/**
 * Which AI provider processed the extraction.
 */
export type ProviderType = 'foundation-models' | 'claude' | 'gemini' | 'built-in';
/**
 * Metadata about how the scan was processed.
 */
export interface VisaraMetadata {
    /** Which provider ran the extraction */
    provider: ProviderType;
    /** Total processing time in seconds */
    processingTime: number;
    /** How clearly the OCR read the image — 0.0 to 1.0 */
    ocrConfidence: number;
}
/**
 * The complete result of a Visara scan.
 *
 * Every scan returns this shape — regardless of which provider ran.
 * Mirrors VisaraResult in Swift.
 */
export interface VisaraResult {
    /** The full raw text extracted from the image */
    rawText: string;
    /** All detected entities as a flat array */
    entities: VisaraEntity[];
    urls: string[];
    phones: string[];
    emails: string[];
    dates: string[];
    prices: string[];
    discounts: string[];
    socialHandles: string[];
    addresses: string[];
    /** How the scan was processed */
    metadata: VisaraMetadata;
}
/**
 * Configuration options for Visara.
 * All fields are optional — the library works with zero configuration.
 */
export interface VisaraOptions {
    /**
     * Which AI provider to use.
     * Defaults to 'auto' — Visara picks the best available option.
     */
    provider?: 'auto' | 'foundationModels' | 'claude' | 'gemini' | 'builtIn';
    /** Your Claude API key — required if using Claude provider */
    claudeAPIKey?: string;
    /** Your Gemini API key — required if using Gemini provider */
    geminiAPIKey?: string;
    /** Timeout in seconds. Default: 30 */
    timeout?: number;
}
/**
 * Configure Visara before scanning.
 * Optional — the library works with zero configuration.
 *
 * Call once at app startup, before any scan() calls.
 *
 * @example
 * Visara.configure({
 *   provider: 'claude',
 *   claudeAPIKey: 'sk-ant-...'
 * });
 */
export declare function configure(options: VisaraOptions): void;
/**
 * Scan an image and return structured data.
 *
 * This is the primary function of the library.
 * Pass any image path — from camera, photo library, or file system.
 *
 * @param imagePath - Absolute path or file:// URL to the image
 * @returns Structured data extracted from the image
 *
 * @example
 * // Zero config — works immediately
 * const result = await Visara.scan(imagePath);
 * console.log(result.urls);    // ['nike.com']
 * console.log(result.phones);  // ['512-555-0123']
 *
 * @example
 * // With error handling
 * try {
 *   const result = await Visara.scan(imagePath);
 *   if (result.urls.length > 0) {
 *     Linking.openURL(result.urls[0]);
 *   }
 * } catch (error) {
 *   console.error('Scan failed:', error);
 * }
 */
export declare function scan(imagePath: string): Promise<VisaraResult>;
/**
 * Scan a programmatically generated test image.
 * No image path required — useful for verifying the pipeline works.
 */
export declare function scanDemo(): Promise<VisaraResult>;
/**
 * Default export — use as a namespace if preferred.
 *
 * @example
 * import Visara from '@visara/core';
 * const result = await Visara.scan(imagePath);
 */
declare const _default: {
    configure: typeof configure;
    scan: typeof scan;
    scanDemo: typeof scanDemo;
};
export default _default;
//# sourceMappingURL=index.d.ts.map