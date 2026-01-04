# AGENTS.md

## Tech Stack & Dependencies
- Language/runtime: Swift 5.9 (Swift Package Manager)
- UI framework: SwiftUI (macOS menu bar app)
- Platform targets: macOS 13.0+ (Xcode 15.0+ recommended)
- Key dependency:
  - GRDB.swift 6.29.3: SQLite persistence layer (see `Package.resolved`)
- Environment requirements:
  - macOS 13.0+ with Xcode 15.0+ for building/running
- Development tooling:
  - Python 3.9+ with Pillow (for icon processing script in `scripts/`)

## Project Structure
- Architecture: single-package SwiftPM app with layered directories (Models/Views/Services)
- Key directories:
  - `Sources/VibeWatch/`: app source code
    - `Sources/VibeWatch/Models/`: data types like `DailyRecord`, `TimeEntry`, `AppSettings`
    - `Sources/VibeWatch/Services/`: business logic (tracking, persistence, app detection)
    - `Sources/VibeWatch/Views/`: SwiftUI UI surfaces (menu bar dropdown, history, settings)
    - `Sources/VibeWatch/Resources/`: icon assets (eye icons for menu bar states)
    - `Sources/VibeWatch/AppDelegate.swift`: app lifecycle integration
    - `Sources/VibeWatch/VibeWatchApp.swift`: SwiftUI entry point
    - `Sources/VibeWatch/Info.plist`: app bundle metadata
  - `Tests/VibeWatchTests/`: XCTest unit tests
  - `scripts/`: development utilities (icon processing, etc.)
  - `docs/`: project documentation
    - `docs/guides/`: onboarding/how-to (`docs/guides/quick-start.md`)
    - `docs/product/`: product/requirements docs
    - `docs/debugging/`: known issues and troubleshooting
    - `docs/ai/rules/`: internal prompt/rules docs
- No separate sub-projects; no hierarchical `AGENTS.md` needed.

## Development Commands
- Build (debug): `swift build`
- Run (debug): `swift run`
- Open in Xcode: `open Package.swift`
- Release build: `swift build --configuration release`
- Notes:
  - Dependencies are resolved automatically by SwiftPM (no separate install step)
  - There are no npm/yarn/make scripts in this repo

## Testing Strategy
- Framework: XCTest (`import XCTest` in `Tests/VibeWatchTests/`)
- Run tests: `swift test`
- Test location and examples:
  - `Tests/VibeWatchTests/TimeTrackerTests.swift`
  - `Tests/VibeWatchTests/AppDetectorTests.swift`
  - `Tests/VibeWatchTests/IdleMonitorTests.swift`
- No explicit coverage thresholds or CI gates defined in the repo.

## Code Style & Standards
- No explicit lint/format tooling (no SwiftLint/SwiftFormat config present).
- Naming:
  - Types and protocols: `PascalCase` (e.g., `TimeTracker`, `DailyRecord`)
  - Methods/properties: `camelCase` (e.g., `getTimeRemaining`, `todayRecord`)
- Organization:
  - Keep UI in `Sources/VibeWatch/Views/`
  - Keep business logic in `Sources/VibeWatch/Services/`
  - Keep shared data structures in `Sources/VibeWatch/Models/`
- Architectural pattern:
  - Simple layered design (models + services + SwiftUI views), with app lifecycle in `AppDelegate`.

## Boundaries & Constraints
- Never commit secrets or credentials (none should live in this repo).
- Do not commit generated build artifacts:
  - `.build/` (SwiftPM build output)
  - `DerivedData/` (Xcode)
- Runtime data is local-only; do not commit user data:
  - `~/Library/Application Support/VibeWatch/vibewatch.sqlite`
- `Sources/VibeWatch/Info.plist` is app metadata; change only when needed for bundle settings.
- Deprecated/avoid:
  - Introducing external network calls or telemetry (app is local-only by design).

## Git Workflow
- Branching strategy: not documented; assume feature branches targeting `main`.
- Commit message conventions: not specified in repo.
- PR/review requirements: not specified in repo.
- Pre-commit hooks/automated checks: none found.
