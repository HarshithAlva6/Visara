# Visara

> From Latin *visus* (to see) and Sanskrit *ara* (swift) — **to see, instantly.**

Visara is an open source library that reads physical information from any image and returns structured, actionable data — links, prices, dates, contacts, discounts — with a single function call.

Built on Swift. Works everywhere.

---

## What It Does

Point at anything — an event flyer, a restaurant menu, a shop window, a business card — and Visara tells you everything that's in it.

```typescript
const result = await Visara.scan(imagePath);
// Returns links, phones, dates, prices, discounts, social handles — all structured
```

---

## How It Works

Visara uses a tiered intelligence pipeline, automatically selecting the best available option on every device:

- **On modern devices** — Apple's on-device AI runs entirely on the device. No cost. No internet. No data leaves the phone.
- **On all other devices** — Falls back to a cloud AI provider of your choice (Claude, Gemini, or OpenAI) using your own API key.
- **With no configuration at all** — Apple's built-in text detection extracts links, phones, dates, and addresses for free on every iPhone.

---

## Design Principles

- **Zero config** — works out of the box with no setup
- **Bring your own AI** — supports any major LLM provider
- **Language agnostic output** — same structured result regardless of provider
- **Privacy first** — on-device processing whenever possible
- **SOLID architecture** — open for extension, never requires forking

---

## Supported Platforms

| Platform | Support |
|---|---|
| React Native (Expo) | Coming soon |
| React Native (bare) | Coming soon |
| Swift / iOS (SPM) | Coming soon |

---

## Build Progress

| Milestone | Status |
|---|---|
| Project structure and architecture | ✅ Complete |
| On-device OCR engine | 🔄 In progress |
| Zero-config extraction | Upcoming |
| JavaScript bridge | Upcoming |
| On-device AI provider (iOS 26+) | Upcoming |
| Cloud AI providers (Claude, Gemini) | Upcoming |
| Unit tests | Upcoming |
| CI/CD pipeline | Upcoming |
| npm release | Upcoming |

---

## Contributing

Visara is in active development. Star the repo to follow progress.

---

## License

MIT
