# How we built it

Notes from building an iOS reference app for PromptIQ using Claude Code in a single session.

## The slice

Smallest interaction that exercises the API end-to-end and feels like a real app:

> **Browse my PromptIQ prompts → tap one → copy or share. Create a new prompt.**

We deliberately scoped out edit/delete, search/filter, and offline cache — they're listed as "what's next" in the README but would have doubled the code without changing the demo's point.

## Research findings (before any code was written)

Three things we needed to nail down before scaffolding:

**1. The API surface.** Reading `netlify/functions/prompts.js` directly was faster than guessing from the web UI. Confirmed:
- `GET /api/prompts` returns `{ prompts: [...] }`.
- `POST /api/prompts` takes a v2 prompt JSON. Required fields: `name` (slug), `category` (one of 10), `purpose`, `verbatim`. Everything else optional.
- Auth is a single shared secret on `X-PromptIQ-Key`.

**2. The auth model.** The "secret" is published at `https://h9-prompt-iq.netlify.app/config.local.js`, fetched by the web client at runtime. That made the iOS auth design easy: do the same thing. `KeyProvider` is a 40-line actor that downloads that file once, regexes out the key, and caches it. Zero secrets ship in the iOS binary; key rotations propagate automatically.

**3. The data model.** The 32 built-in prompts live in `mcp-server/prompts.json` as a top-level array. The schema has 23 fields — most optional. Modeled `Prompt` with everything optional except `name` and `category` to be resilient to API drift.

## Project setup

The dev machine had Command Line Tools but not full Xcode. `xcodebuild` errors out without an Xcode.app, so we couldn't build or boot a Simulator from CLI. Workaround: scaffold all sources, write an [XcodeGen](https://github.com/yonaskolb/XcodeGen) `project.yml`, and document a `brew install xcodegen && xcodegen generate && open …` flow. User installs Xcode in parallel; once it's done, they have a buildable project.

Deployment target: iOS 17. Justification: `@Observable`, `ShareLink`, and `NavigationStack` are all clean there, no `@StateObject`/`ObservableObject` boilerplate.

## Architecture

```
App  ─►  PromptLibrary (@Observable)  ─►  PromptIQClient  ─►  KeyProvider (actor)
                  │
                  └─►  bundled prompts.json (built-ins)
```

- `KeyProvider` is an `actor` — concurrent calls during cold start can't double-fetch.
- `PromptIQClient` is a `struct` with a shared instance, stateless other than the `baseURL`.
- `PromptLibrary` is `@MainActor @Observable`; injected via SwiftUI's `.environment`.
- Views are dumb — they read from the environment and call methods on it.

## Things we deliberately did not do

- **No third-party packages.** URLSession + Codable + SwiftUI ship everything we need. Adding Alamofire / Moya / Tuist would obscure what the example is teaching.
- **No abstract `APIClient` protocol.** One concrete client, one set of methods. The day we need to swap implementations is the day to write the protocol — not before.
- **No persistence layer.** SwiftData / CoreData / UserDefaults add surface area unrelated to the API demo. Custom prompts re-fetch on launch; that's fine for v1.
- **No Info.plist file.** Xcode 15+ generates it from `INFOPLIST_KEY_*` build settings declared in `project.yml`.

## What Claude Code did well

- Reading `_auth.js` and `prompts.js` directly to nail the contract instead of asking the user to summarize them.
- Catching the Xcode-vs-CLT distinction early (`xcodebuild -version` failed loudly) and surfacing it as a blocker before writing any code.
- Confirming the snapshot file shape (`Array.isArray(j)`) with a one-line Node check before writing the `JSONDecoder().decode([Prompt].self, …)` call.

## What needed user input

Three scoping decisions were taste-driven, not derivable from the code: standalone repo vs in-tree, read-only vs read+create, built-ins vs customs vs both. Each was a 30-second `AskUserQuestion`. The remaining "where on disk" and "key handling" questions came after the research turned up specifics.

## H9 brand pass

After the first working build, applied the H9 Partners brand from `H9_Partners_Branding_Guidelines.pptx`:

- **Colors** — Orange `#FF8C00`, Navy `#142338`, Cream `#FAF8F4`, Light Gray `#F0F0F0`, Text Black `#1E1E1E`. Centralized in `Brand/Brand.swift` as both `Color` and `UIColor` constants (the latter for UIKit appearance proxies).
- **Typography** — Posterama2001-Thin (the brand display font) is bundled in `Resources/Fonts/` and declared via `UIAppFonts` in the xcodegen-generated `Info.plist`. PostScript name is `Posterama2001-Thin` (no space). Used for the brand header, nav-bar titles, and section labels. Body text stays on system font for legibility.
- **Global appearance** — `Brand.configureAppearance()` runs from `App.init()` and sets `UINavigationBarAppearance` to navy background + white Posterama title + orange tint for bar items. `.tint(Brand.orange)` on the root view propagates the accent to the rest of SwiftUI.
- **Header lockup** — Navy card at the top of the list view with the "H9 PARTNERS" wordmark in a thin orange outlined box (echoes the actual logo), "PROMPT IQ" in big Posterama below, and "AVIATION INFRASTRUCTURE REIMAGINED" tagline underneath.
- **Visual motif** — Repeated 3pt orange vertical rule before every section label, carried across list, detail, and new-prompt sheet. One small thing, consistent everywhere — gives the brand a fingerprint.

The logo PNG is bundled but unused in v1 — the file has a white background that conflicts with the navy header. Future polish: pre-process to transparent white pixels, then drop it back into the header.

## Open items

- Verify the `POST /api/prompts` path against a live deploy — code is written but un-exercised end-to-end. Manual test from the simulator: tap +, fill out the form, save, pull-to-refresh.
- Capture detail-view and new-prompt-sheet screenshots. Blocked on Accessibility permission for the terminal process (can't drive taps via AppleScript). Easiest path: tap manually in the Simulator window, then `xcrun simctl io <udid> screenshot screenshots/02-detail.png`.
- App icon — currently a default placeholder. The brand calls for a navy square with orange "H9" lockup; needs Asset Catalog setup.
- Decide if the snapshot `prompts.json` should be regenerated via a Makefile / script when the upstream PromptIQ repo changes.
