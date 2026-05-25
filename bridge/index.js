"use strict";
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
Object.defineProperty(exports, "__esModule", { value: true });
exports.configure = configure;
exports.scan = scan;
exports.scanDemo = scanDemo;
const expo_modules_core_1 = require("expo-modules-core");
// Load the native Swift module
const VisaraNative = (0, expo_modules_core_1.requireNativeModule)('Visara');
// ─────────────────────────────────────────────
// MARK: - Public API
// ─────────────────────────────────────────────
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
function configure(options) {
    VisaraNative.configure(options);
}
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
async function scan(imagePath) {
    return VisaraNative.scan(imagePath);
}
/**
 * Scan a programmatically generated test image.
 * No image path required — useful for verifying the pipeline works.
 */
async function scanDemo() {
    return VisaraNative.scanDemo();
}
/**
 * Default export — use as a namespace if preferred.
 *
 * @example
 * import Visara from '@visara/core';
 * const result = await Visara.scan(imagePath);
 */
exports.default = { configure, scan, scanDemo };
//# sourceMappingURL=index.js.map