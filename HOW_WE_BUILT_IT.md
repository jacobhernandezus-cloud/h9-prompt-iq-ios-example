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

## Open items

- ~~Run in the Simulator and capture screenshots / a screen recording.~~ ✅ Done — see `screenshots/01-list.png`. App built and launched first-try on Xcode 26.5, iPhone Air simulator. The list view rendered all 32 bundled built-ins correctly, sectioned, with category chips and status labels.
- Verify the `POST /api/prompts` path against a live deploy — code is written but un-exercised. Manual test from the simulator: tap +, fill out the form, save.
- Capture detail-view and new-prompt-sheet screenshots. Blocked on Accessibility permission for the terminal process (can't drive taps via AppleScript). Easiest path: tap manually in the Simulator window, then `xcrun simctl io <udid> screenshot screenshots/02-detail.png`.
- Decide if the snapshot `prompts.json` should be regenerated via a Makefile / script when the upstream PromptIQ repo changes.
