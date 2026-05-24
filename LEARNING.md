# Visara — Personal Learning Journal

My personal record of every Swift and iOS concept learned while building Visara.
Written in plain language. Updated as we build.

---

## Table of Contents

1. [Project Architecture](#1-project-architecture)
2. [SOLID Principles in Swift](#2-solid-principles-in-swift)
3. [Swift Protocols](#3-swift-protocols)
4. [async/await — Modern Concurrency](#4-asyncawait)
5. [Vision Framework — OCR](#5-vision-framework)
6. [NSDataDetector — Zero Config Extraction](#6-nsdatadetector)
7. [Codable — JSON in Swift](#7-codable)
8. [URLSession — Networking](#8-urlsession)
9. [Error Handling in Swift](#9-error-handling)
10. [Apple Foundation Models](#10-foundation-models)
11. [Expo Bridge](#11-expo-bridge) — upcoming
12. [Unit Testing](#12-unit-testing) — upcoming
13. [CI/CD](#13-cicd) — upcoming

---

## 1. Project Architecture

### What we built
A library that takes an image and returns structured data.

### The flow
```
UIImage
  → OCREngine        (reads text from image)
  → ExtractionPipeline  (picks the best AI provider)
  → ExtractionProvider  (extracts structured entities)
  → VisaraResult     (the final typed output)
```

### Why this structure works
Each layer has one job. You can replace any layer without touching the others.
This is the foundation of maintainable software.

---

## 2. SOLID Principles in Swift

SOLID is a set of five design principles. We applied all five in Visara.

### S — Single Responsibility
Each file does exactly one thing.
- `OCREngine` reads images. That's it.
- `ExtractionPipeline` picks a provider. That's it.
- `VisaraScanner` coordinates the flow. That's it.

### O — Open/Closed
Open for extension, closed for modification.
- `EntityType` has `.custom(String)` — anyone can add new entity types without editing the file.
- Adding a new AI provider means adding a new file, not changing existing ones.

### L — Liskov Substitution
Any provider can replace any other provider.
- `ClaudeProvider` and `GeminiProvider` both implement `ExtractionProvider`.
- The pipeline calls `.extract()` — it doesn't care which one it's talking to.
- Swap providers freely. The rest of the library never changes.

### I — Interface Segregation
One focused protocol, not a large bloated one.
- `ExtractionProvider` has only what it needs: `name`, `isAvailable`, `extract(from:)`.
- Providers don't implement functions they don't need.

### D — Dependency Inversion
High-level code depends on abstractions, not implementations.
- `ExtractionPipeline` depends on `ExtractionProvider` (protocol), not on Claude or Gemini directly.
- We can add a new provider without the pipeline ever knowing about it.

---

## 3. Swift Protocols

A protocol is a contract. It says:
"Any type that claims to be X MUST provide these things."

```swift
protocol ExtractionProvider {
    var name: String { get }
    var isAvailable: Bool { get }
    func extract(from text: String) async throws -> [VisaraEntity]
}
```

Any class or struct can implement this. The caller never needs to know which one it is.

**Why protocols over inheritance?**
Inheritance creates tight coupling. Protocols allow loose coupling.
In Swift, you can't inherit from multiple classes — but you can implement multiple protocols.
This is why Swift favours protocols over class hierarchies.

---

## 4. async/await

The modern way to handle work that takes time (network calls, file reads, OCR).

```swift
// Old way — callback hell
URLSession.shared.dataTask(with: request) { data, response, error in
    // nested inside a closure
    // error handling gets messy
}

// New way — async/await
let (data, response) = try await URLSession.shared.data(for: request)
// reads like synchronous code, runs asynchronously
```

**Key concepts:**
- `async` — this function does background work
- `await` — pause here until the result is ready, but don't block the UI
- `throws` — this function can fail, caller must handle the error
- `try` — I know this can throw, I'm handling it

**withCheckedThrowingContinuation:**
Used in OCREngine to convert Vision framework's old callback style into async/await.
This is the standard bridge pattern between legacy Apple APIs and modern Swift.

```swift
let result = try await withCheckedThrowingContinuation { continuation in
    // old callback code here
    continuation.resume(returning: value)  // success
    continuation.resume(throwing: error)   // failure
}
```

---

## 5. Vision Framework

Apple's on-device computer vision library. Free. No internet. Works on iOS 13+.

**VNRecognizeTextRequest** — the OCR tool inside Vision.
- `.accurate` mode — slower but better for small text on signs and flyers
- `.usesLanguageCorrection` — fixes obvious spelling mistakes in extracted text
- Returns `VNRecognizedTextObservation` — each observation is one line of text
- `.topCandidates(1)` — returns the most likely reading of each line

**How we used it:**
```swift
let request = VNRecognizeTextRequest { request, error in
    let observations = request.results as? [VNRecognizedTextObservation]
    // extract text from observations
}
request.recognitionLevel = .accurate
let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
try handler.perform([request])
```

---

## 6. NSDataDetector

Apple's built-in structured text detector. Finds real-world data patterns in strings.

**What it detects:**
- `.phoneNumber` — phone numbers in any format
- `.link` — URLs and web addresses
- `.date` — dates and times
- `.address` — physical addresses

**Why it's powerful:**
- No AI. No API. No cost. No internet.
- More accurate than regex for these patterns.
- Works offline on every iPhone.

**How we combined types:**
```swift
let types: NSTextCheckingResult.CheckingType = [.phoneNumber, .link, .date, .address]
let detector = try NSDataDetector(types: types.rawValue)
```

The `|` operator combines multiple detector types in one pass. Efficient.

---

## 7. Codable

Swift's built-in system for converting between Swift structs and JSON.

```swift
struct ClaudeRequest: Encodable {
    let model: String
    let maxTokens: Int

    // When the JSON key name differs from the Swift property name
    enum CodingKeys: String, CodingKey {
        case model
        case maxTokens = "max_tokens"  // JSON uses snake_case
    }
}
```

- `Encodable` — Swift struct → JSON (sending to API)
- `Decodable` — JSON → Swift struct (receiving from API)
- `Codable` — both directions

No manual JSON parsing. No dictionary lookups. Type-safe throughout.

---

## 8. URLSession

Apple's built-in HTTP networking. No third-party libraries needed.

```swift
var request = URLRequest(url: endpoint)
request.httpMethod = "POST"
request.setValue("application/json", forHTTPHeaderField: "Content-Type")
request.httpBody = try JSONEncoder().encode(requestBody)

let (data, response) = try await URLSession.shared.data(for: request)
```

**Why no Alamofire?**
Libraries should have zero dependencies where possible.
Every iOS app has URLSession. Using it keeps Visara lightweight.

---

## 9. Error Handling

Swift errors are typed. We define exactly what can go wrong.

```swift
enum VisaraError: Error {
    case ocrFailed(String)
    case lowConfidence(Double)
    case noProviderAvailable
    case extractionFailed(String)
    case timeout
    case missingAPIKey(String)
}
```

**Associated values:** Each case can carry data.
`ocrFailed("Could not read image")` tells the caller WHY it failed.

**Guard statements:**
```swift
guard ocrOutput.confidence >= config.minimumOCRConfidence else {
    throw VisaraError.lowConfidence(ocrOutput.confidence)
}
```
Guard = "if this isn't true, leave." Keeps code flat. Avoids deep nesting.

---

## 10. Apple Foundation Models

iOS 26 ships an on-device ~3B parameter LLM on every eligible device.
Eligible: iPhone 15 Pro+ and all iPhone 16/17 models.

**Key concepts:**
- `LanguageModelSession` — the interface to the on-device model
- `@Generable` macro — produces type-safe Swift structs directly from the model
- Guided generation — the model is constrained at token level to match your struct
- No API key. No cost. No internet. Fully private.

**Why @Generable beats JSON prompting:**
```swift
// Without @Generable — fragile
let jsonString = try await session.respond(to: prompt)
let parsed = try JSONDecoder().decode(...)  // can fail

// With @Generable — type-safe
let result = try await session.respond(to: prompt, generating: ExtractedContent.self)
result.urls  // directly typed [String], never fails to parse
```

**Status:** Placeholder implemented. Will activate when building with Xcode + iOS 26 SDK.

---

## 11. Expo Bridge

### What the bridge is
Swift and JavaScript live in separate worlds.
Swift runs natively. JavaScript runs inside a JS engine (Hermes).
They cannot talk to each other directly.
The bridge is the translator between them.

### The flow
```
JavaScript:  await Visara.scan(imagePath)
                    ↓
         Expo Modules API (bridge)
                    ↓
Swift:       scan(imagePath: String)
Swift:       returns VisaraResult
                    ↓
         Converted to [String: Any] dictionary
                    ↓
JavaScript:  receives { urls: [...], phones: [...] }
```

### Three files make this work
- `expo-module.config.json` — tells Expo this module exists
- `ios/VisaraModule.swift` — Swift class that exposes functions to JS
- `bridge/index.ts` — TypeScript types and clean API for JS developers

### Key concepts

**Name("Visara")** — registers the module so JS can find it
**Function** — synchronous bridge function (configure)
**AsyncFunction** — async bridge function (scan) — can await, can throw
**requireNativeModule('Visara')** — JS side loads the native module by name

### What can cross the bridge
Only primitive types can cross between Swift and JavaScript:
- String → string
- Double → number
- Bool → boolean
- [Any] → Array
- [String: Any] → Object

Swift structs, enums, and classes cannot cross directly.
We serialize VisaraResult into a [String: Any] dictionary first.

### TypeScript types
Even though the bridge is untyped at runtime,
we define TypeScript interfaces that describe the exact shape.
This gives developers autocomplete and compile-time safety.

### Why Expo Modules API over the old bridge
The old React Native bridge used Objective-C macros and was verbose.
Expo Modules API is Swift-first, cleaner, and handles async natively.
It's the modern standard for native modules in 2026.

---

## 12. Unit Testing

### XCTest — the framework
Apple's built-in testing framework. Every test class inherits from XCTestCase.
Every function starting with `test` is automatically discovered and run.

### Structure of a good test — Given / When / Then
```swift
func test_provider_detectsURL() async throws {
    // Given — set up conditions
    let provider = BuiltInProvider()
    let text = "Visit nike.com"

    // When — perform the action
    let entities = try await provider.extract(from: text)

    // Then — assert expected result
    XCTAssertTrue(entities.contains { $0.type == .url })
}
```

### Key XCTest assertions
```swift
XCTAssertEqual(a, b)           // a equals b
XCTAssertNotEqual(a, b)        // a does not equal b
XCTAssertTrue(condition)       // condition is true
XCTAssertFalse(condition)      // condition is false
XCTAssertNil(value)            // value is nil
XCTAssertNotNil(value)         // value is not nil
XCTAssertGreaterThan(a, b)     // a > b
XCTAssertLessThan(a, b)        // a < b
XCTFail("message")             // force a test failure
XCTAssertEqual(a, b, accuracy: 0.001) // floating point comparison
```

### setUp and tearDown
```swift
override func setUp() {
    super.setUp()
    scanner = VisaraScanner()  // fresh state before EVERY test
}

override func tearDown() {
    scanner = nil              // clean up after EVERY test
    super.tearDown()
}
```
Tests must never share state. Shared state causes flaky tests.

### @testable import
Gives test files access to internal types without making them public.
```swift
@testable import Visara  // can now see internal classes and functions
```

### Async testing
Just mark the test function async — XCTest handles the rest.
```swift
func test_something() async throws {
    let result = try await provider.extract(from: text)
    XCTAssertFalse(result.isEmpty)
}
```

### Mocking — the payoff of protocols
Because ExtractionProvider is a protocol, we can create fake implementations.
```swift
final class MockSuccessProvider: ExtractionProvider {
    var entitiesToReturn: [VisaraEntity] = []

    func extract(from text: String) async throws -> [VisaraEntity] {
        return entitiesToReturn  // always returns what we set
    }
}
```
No network. No API keys. No randomness. Pure, predictable tests.
This is why SOLID D (Dependency Inversion) matters for testability.

### Unit vs Integration tests
- Unit test: tests ONE thing in isolation (one function, one class)
- Integration test: tests multiple things working together (full pipeline)
Both are valuable. Write unit tests first.

### Programmatic UIImage for tests
We can't use camera images in tests — so we render text programmatically.
```swift
let renderer = UIGraphicsImageRenderer(size: CGSize(width: 400, height: 200))
let image = renderer.image { context in
    UIColor.white.setFill()
    context.fill(...)
    text.draw(at: ..., withAttributes: ...)
}
```
This creates a real UIImage with real text that OCREngine can process.

---

## 13. CI/CD with GitHub Actions

### What CI/CD means
- **CI** — Continuous Integration: automatically build and test on every push
- **CD** — Continuous Delivery: automatically publish when a release is tagged

### Why it matters
Without CI, you only know code is broken when someone tells you.
With CI, you know within minutes of pushing. Every time. Automatically.

### How GitHub Actions works
```
You push code
    ↓
GitHub detects the push
    ↓
Spins up a fresh virtual machine (Mac for Swift, Ubuntu for TS)
    ↓
Runs your workflow steps in order
    ↓
Reports pass ✅ or fail ❌ on the commit
```

### Key YAML concepts
```yaml
on:                          # WHEN to run
  push:
    branches: [main]         # on every push to main
  pull_request:
    branches: [main]         # on every PR to main

jobs:                        # WHAT to run
  my-job:
    runs-on: macos-latest    # which machine type
    steps:
      - uses: actions/checkout@v4   # clone the repo
      - run: swift test             # run a command
```

### The two workflows we built

**ci.yml** — runs on every push and PR
- Job 1: swift build + swift test (on Mac runner)
- Job 2: TypeScript type check (on Ubuntu runner)
- Blocks merging if either job fails

**release.yml** — runs when you push a version tag
- Job 1: runs all tests (safety gate)
- Job 2: only runs if tests pass → publishes to npm
- Also creates a GitHub Release with auto-generated notes

### How to trigger a release
```bash
# 1. Update version in package.json
# 2. Commit
git commit -am "release: v1.0.0"
# 3. Tag
git tag v1.0.0
# 4. Push both
git push && git push --tags
# GitHub does the rest automatically
```

### Secrets — keeping keys safe
API keys are never hardcoded. They live in GitHub Secrets.
```yaml
env:
  NODE_AUTH_TOKEN: ${{ secrets.NPM_TOKEN }}
```
Set at: GitHub repo → Settings → Secrets and variables → Actions

### needs: — job dependencies
```yaml
publish:
  needs: test    # won't start until `test` job passes
```
This is the safety gate. Broken code never reaches npm.

### GITHUB_TOKEN
GitHub automatically provides this secret on every runner.
Used for creating releases, commenting on PRs, etc.
You never need to set it manually.
