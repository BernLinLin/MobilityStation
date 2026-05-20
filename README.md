# MobilityStation

MobilityStation is an iOS app for exploring urban bike-sharing stations. It focuses on a reliable, reviewable implementation of the assignment requirements: station list, station detail, favorites persistence, offline fallback behavior, and a clean architecture that is easy to explain in follow-up discussion.

## Assignment Coverage

This submission covers the core assignment requirements:

- iOS only, written in Swift
- SwiftUI-based UI
- Minimum deployment target: iOS 16
- Async/await-based data loading
- Working list UI with loading, empty, refresh, search, sort, and favorites filtering
- Station detail screen with availability, location, and map integration
- Favorites persistence across app launches
- Offline-friendly reviewability through cache and bundled fallback data

## Data Source

The app uses a single live data source:

- `https://api.citybik.es/v2/networks/velib`

Implementation details:

- Base API host: `https://api.citybik.es/v2/`
- Requested network: `velib`
- No other live APIs are used
- When the live request is unavailable, the app falls back to local cache and then to bundled fallback JSON

## Architecture

The project uses a lightweight layered architecture designed for clarity and maintainability rather than heavy modularization.

### Layers

- `API`
  - Defines endpoints, request types, response models, and service logic
  - Main files: `StationRequest.swift`, `StationService.swift`, `StationModels.swift`
- `CustomUI`
  - Contains SwiftUI views and view models for list, detail, and reusable components
- `Tools`
  - Contains networking primitives, error definitions, and persistence/cache logic
- `Resources`
  - Contains bundled fallback station data

### Responsibility Split

- `StationService`
  - Fetches live station data from CityBikes
  - Maps decoded API responses into app view models
- `StationListViewModel`
  - Owns list state, loading, refresh, search, filtering, sorting, and error presentation
  - Coordinates remote data, local cache, and persisted favorites
- `StationDetailViewModel`
  - Handles detail-screen favorite toggling
- `StationStore`
  - Persists cached station snapshots
  - Persists favorite station IDs
  - Loads cached data and bundled fallback data
  - Uses `actor` isolation for persistence access

### Data Flow

1. `StationListView` triggers an initial load.
2. `StationListViewModel` asks `StationService` for live station data.
3. On success, the fetched stations are normalized and cached locally.
4. Persisted favorites are reapplied to the loaded stations.
5. On failure, the app first attempts to load cached stations.
6. If cache is unavailable, the app loads bundled fallback JSON.
7. Favorite IDs are stored separately, so favorites remain useful even when fresh data cannot be loaded.

This keeps remote freshness concerns separate from user-owned favorite state and makes the app more resilient in offline scenarios.

## Feature Summary

- Station list
  - Loading state
  - Empty state
  - Error alert
  - Search
  - Sort
  - Favorites filter
  - Pull to refresh
- Station detail
  - Availability metrics
  - Status indicators
  - Location and map preview
  - Open in Apple Maps
- Favorites
  - Toggle from list and detail
  - Persist across launches
- Offline support
  - Cached station snapshots
  - Bundled fallback JSON resource

## Persistence And Offline Strategy

The app uses a simple persistence model that fits the assignment scope:

1. Successful live responses are stored as JSON snapshots in `Application Support`.
2. Favorite station IDs are stored in `UserDefaults`.
3. If a live fetch fails, the app first attempts to use cached station data.
4. If cached data is unavailable, the app loads `stations_fallback.json` from the app bundle.
5. Favorite IDs are reapplied after loading, regardless of whether the source is live, cache, or fallback data.

This approach intentionally favors simplicity, reviewability, and predictable behavior over a more complex database-backed cache.

## Running The App

Requirements:

- Xcode 16+
- iOS 16+

Run steps:

1. Open `MobilityStation.xcodeproj`
2. Select the `MobilityStation` scheme
3. Run on an iOS 16+ simulator or device

## Verification

I verified the submission in the following ways:

### Build Verification

- Ran:
  - `xcodebuild -scheme MobilityStation -project MobilityStation.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' build`
- Result:
  - `BUILD SUCCEEDED`

### Cache And Fallback Verification

- Confirmed that successful fetches are written into local cache through `StationStore`
- Confirmed that network failure falls back to cached stations before bundled fallback data
- Confirmed that `stations_fallback.json` is copied into the built app bundle
- Confirmed that favorites are persisted independently and reapplied to loaded station data

### Test Coverage

The current unit tests cover:

- search behavior
- sorting behavior
- favorites filtering
- favorite persistence
- cache-before-fallback behavior
- fallback JSON decoding

Observed status:

- `MobilityStationTests` pass
- full `xcodebuild test` is still blocked by the current UI test bundle configuration

## Trade-Offs

- The app uses a single-target structure for faster delivery and easier review
- Persistence is intentionally lightweight: JSON cache plus `UserDefaults`
- Error handling focuses on user-facing recovery paths rather than logging or analytics infrastructure
- The architecture is layered and testable, but not over-engineered for the assignment scope

## AI Tool Usage

AI assistance was used in a limited and targeted way, mainly around the caching and offline-support implementation.

AI-assisted areas:

- refining the cache and favorites persistence approach
- shaping parts of the `StationStore` design
- checking fallback behavior and validation strategy
- helping document the final submission clearly

AI was not used as a substitute for the full app design or final implementation ownership. I reviewed and adjusted the AI-assisted code before keeping it in the project.

## How I Verified AI-Assisted Work

The AI-assisted caching and fallback logic was verified by:

1. building the app successfully
2. reviewing the success path that writes cache data
3. reviewing the failure path that loads cache before bundled fallback
4. verifying that fallback JSON is packaged into the app bundle
5. running unit tests that specifically cover cache, fallback, and persistence behavior

