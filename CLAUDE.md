# CLAUDE.md — Přelez

Apple-native climbing companion for the Vertikon gym in Zlín. Semester project for
AP9PT „Pokročilé mobilní technologie“ (UTB FAI, ZS 2026/27). The code is written with
Claude Code, and the student has to explain every line at the defense. Keep the code
simple, explicit and readable. Avoid clever abstractions.

## Non-negotiable requirements
The defense checks these. Never regress them:
1. SwiftUI app: one multiplatform target for iOS and macOS.
2. SwiftData persistence. Data must survive a real restart: kill the app. Pressing ■ in Xcode is not a restart.
3. An on-device AI feature (Foundation Models) with an eval of ≥ 5 golden cases. We keep ≥ 12 cases.
   The eval must be able to fail, which the `DumbRouteResolver` test proves.
4. At least one App Intent that runs from Shortcuts without opening the app.

The spec is `docs/PRD.md`, with features F1… and acceptance criteria A1….
- Every change maps to an F/A number.
- Anything under „Mimo rozsah“ is out of scope. Do not add it without updating the PRD first.

Every bug the agent introduces that tests or clicking later catch goes into `docs/AGENT-BUGS.md`
(symptom → how it was found → fix). The student uses it at the defense.

## Toolchain
- Xcode 27, Swift 6 language mode, default actor isolation `MainActor`, approachable concurrency.
- Deployment targets: iOS 26.0 and macOS 26.0. The home Mac runs macOS 26.6; school Macs run macOS 27.
  Guard 27-only APIs with `if #available(iOS 27, macOS 27, *)`.
- XcodeGen generates the project from `project.yml`. Change targets or settings there, then run
  `xcodegen generate`. Source folders are synced, so adding a file needs no regeneration.
- Check unfamiliar APIs against the SDK `.swiftinterface` files
  (`/Applications/Xcode.app/Contents/Developer/Platforms/*/Developer/SDKs/*.sdk/System/Library/Frameworks/<Name>.framework/Modules`).
  Never invent frameworks, types or modifiers.

## Commands
```sh
xcodegen generate

# iOS build (iPhone 18 Pro has a Dynamic Island)
xcodebuild -project Prelez.xcodeproj -scheme Prelez \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro,OS=27.0' build

# macOS build + all tests (the Foundation Models eval only runs when Apple Intelligence is on)
xcodebuild -project Prelez.xcodeproj -scheme Prelez -destination 'platform=macOS,arch=arm64' test

# only the AI eval
xcodebuild -project Prelez.xcodeproj -scheme Prelez -destination 'platform=macOS,arch=arm64' test \
  -only-testing:PrelezTests/RouteResolverEvalTests

# Debug launch arguments (screenshots, defense demo): sample data + chosen tab
xcrun simctl launch booted cz.utb.ap9pt.prelez -demoData -tab routes
```

## Architecture
```
Prelez/
  App/        PrelezApp, AppModelContainer (the ONE shared ModelContainer for app + intents)
  Models/     SwiftData @Model classes: Sector, Route, ClimbSession, Attempt
  Domain/     pure logic, no SwiftUI/SwiftData: Grade, HoldColor, RouteTrait, TextFolding, RouteQuery,
              QueryParser, RouteMatcher, RouteInfo (value snapshot of a route), Eval
  AI/         Foundation Models: availability, HybridRouteResolver
  Import/     RoutesSnapshot JSON format + SnapshotImporter
  Intents/    App Intents: RouteEntity, LogAttemptIntent, HardestSendIntent, PrelezShortcuts
  Views/      SwiftUI screens; Views/Components for small reusable views
  Resources/  routes-sample.json (SAMPLE data until the setters' export arrives)
PrelezTests/  Swift Testing: domain unit tests, importer tests, AI eval
docs/         PRD.md, EVAL.md, AGENT-BUGS.md, REVIEW.md
```

Data flow:
1. View → `@Query`/`modelContext` → `@Model`.
2. Domain and AI code never touch SwiftData. They work on `RouteInfo` value snapshots,
   so they stay testable without a database.

## Rules (from the course review checklists)
**Navigation and state**
- Use `NavigationStack` + `navigationDestination(for:)`. Never use `NavigationView`.
- Use `@Observable` classes with `@State`/`@Bindable`/`@Environment`. No `ObservableObject`/`@Published`.

**SwiftData**
- Models are `@Model final class`.
- Attach `.modelContainer(AppModelContainer.shared)` to the scene.
- Read with `@Query`. Write with `modelContext.insert/delete`.
- In intents, use `AppModelContainer.shared.mainContext` and `try context.save()`. Never swallow errors with `try?`.
- Delete model objects, never indices of a filtered array.

**Route data**
- Never delete routes on re-import. Mark routes missing from the snapshot with `isActive = false`,
  so attempt history survives a reset (přestavba).
- Route data comes only from the snapshot JSON the gym's setters provide.
- Do not call 8a.nu or Vertical-Life: they have no public API, sit behind Cloudflare, and their terms of service forbid it.

**Matching**
- Grades are case-sensitive: lowercase is French sport (`6b`), uppercase is Fontainebleau boulder (`6B`).
  Never compare grades case-insensitively.
- Text matching folds diacritics (`žlutá` == `zluta`) but matches whole word forms, not loose prefixes
  (`šedá` → `seda` must not match `sedmička`).

**AI** (see `docs/EVAL.md` for why)
- The model never picks a route. It only translates free text into fixed choices
  (color, sector, route character, outcome) with constrained decoding. The rules pick the route.
- The model never sees or produces grades.
- The on-device model does not support Czech. Czech notes are handled by the rules and the
  `RouteTrait` glossary. Only notes in supported languages go to the model.
- When the model throws, fall back to the rules and set `aiNote`. Never fail the quick log because of AI.
- Always check `SystemLanguageModel.default.availability`, and keep the manual fallback working.
- Every change to prompts or AI logic: rerun the eval and add a row to the history in `docs/EVAL.md`.
  If the score drops, revert.

**UI and platforms**
- Liquid Glass belongs only on the control layer: buttons, bars, accessories, floating controls.
  Never put it on content rows or cards.
- iOS-only APIs (tab bar minimize, bottom accessory, Live Activities, haptics) go inside `#if os(iOS)`.
- Debug-only UI (sample data loaders, reset buttons) goes inside `#if DEBUG`.
- UI text is Czech. Code, identifiers and comments are English.

**Swift 6**
- Use `static let` for intent metadata.
- Pass value types across concurrency boundaries.

## Definition of done for a feature
1. It builds for the iOS Simulator and macOS.
2. Pure logic is covered by Swift Testing tests, and `xcodebuild … test` is green.
3. The matching A-criterion from the PRD is verified by hand. For persistence, that means the restart test.
4. Every agent mistake found along the way is recorded in `docs/AGENT-BUGS.md`.
