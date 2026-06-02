# Fluffy

Fluffy is a SwiftUI iOS marketplace for pets and animal-related services. The product direction is similar to a classified marketplace, but focused on lost pets, found pets, rehoming, shelters, pet-sitting, boarding, chats, favorites, and profile verification.

The production app uses the Vapor backend through API-backed services. Mock services remain behind the same protocols for previews, screenshot generation, and explicit UI-test launch arguments.

## Current Status

- Native SwiftUI app targeting modern iOS.
- MVVM-style screen state through observable view models.
- Auth flow with email/code backend integration, refresh token storage in Keychain using `WhenUnlockedThisDeviceOnly`, and mock fallback for UI tests.
- Marketplace home, search, favorites, chats, profile, detail pages, shelters, pet-sitting, listing creation sheet.
- Russian and English localization through `Localizable.xcstrings`.
- Liquid Glass-inspired visual system.
- Skeleton loading states for client-server screens.
- MapKit integration behind a replaceable map service layer.

## Architecture

The app is split into feature and infrastructure layers:

- `Fluffy/App` - app coordinator, routing, dependency composition.
- `Fluffy/Models` - domain models for marketplace and maps.
- `Fluffy/Services` - API-backed services, protocols, mock implementations for previews/tests, map data, media upload, and session storage.
- `Fluffy/Screens` - SwiftUI screens grouped by feature.
- `Fluffy/UIComponents` - shared UI controls and marketplace components.
- `Fluffy/Support` - theme and visual style helpers.

The dependency entry point is `AppDependencies`. `AppDependencies.live` uses backend services by default; mock services are opt-in for previews and UI-test arguments.

## Maps

Maps are prepared with MapKit and a protocol boundary:

- `MapMarker` describes a map item independent from Apple/Google/Yandex/OSM provider-specific IDs.
- `MapViewport` describes the visible map area requested by the client.
- `MapServicing` is the service protocol.
- `MockMapService` provides local marker data for development.
- `MarketplaceMapView` renders map markers and filters.

The first provider is Apple MapKit because it is native, cheap for an iOS MVP, and works well with SwiftUI. If we later need better Russian address/POI quality, the service boundary lets us move to Yandex, 2GIS, Google, or MapLibre without rewriting the whole app.

## Running

1. Open `Fluffy.xcodeproj` in Xcode.
2. Select the `Fluffy` scheme.
3. Run on an iOS simulator.

Useful launch arguments for UI development:

- `-AppleLanguages (ru)`
- `-AppleLocale ru_RU`
- `-ResetAuthSession`
- `-APIBaseURL http://127.0.0.1:8080`
- `-UseMockAuth`
- `-UITestAuthenticated`
- `-UITestPreloadMarketplaceData`
- `-MockMarketplaceLatencyMS 0`
- `-UITestInitialRoute map`
- `-UITestInitialRoute listingDetail:1`

## Backend Overview

The backend must own all trusted state. The app can display verification, marker, listing, and permission states, but it must never be the source of truth for access control.

Main backend responsibilities:

- Email/code auth and token refresh.
- User profile and verification status.
- Listings with moderation status and geolocation.
- Map markers by viewport, filters, and clustering.
- Favorites.
- Chats and messages.
- Shelters and pet-sitters.
- Media upload and image delivery.
- Abuse reports, moderation, and blocking.

Detailed backend requirements are in [BACKEND_REQUIREMENTS.md](BACKEND_REQUIREMENTS.md).

## Backend Integration

`AppDependencies.live` uses API-backed services by default. Mock marketplace data is kept only for previews and explicit UI-test launch arguments; the production app does not fall back to sample listings, shelters, or pet-sitters.

The auth service calls:

- `POST /api/v1/auth/email/start`
- `POST /api/v1/auth/email/verify`
- `POST /api/v1/auth/refresh`
- `POST /api/v1/auth/logout`

Debug builds default to `http://127.0.0.1:8080`, which works with the iOS simulator when the Vapor backend runs on the same Mac. Release builds default to `https://api.fluffy-infra.ru`. Override either with `-APIBaseURL` or the `FLUFFY_API_BASE_URL` environment variable. UI tests continue to use `MockAuthService` through existing `-UITestAuthEmail` launch arguments.

Marketplace screens call real backend endpoints:

- `GET /api/v1/listings`
- `GET /api/v1/favorites`
- `GET /api/v1/shelters`
- `GET /api/v1/pet-sitters`
- `GET /api/v1/map/markers`
- `GET /api/v1/chats`

When those endpoints return empty arrays, the app shows localized empty states instead of mock content.

## Notes For Future Backend Integration

- Keep API DTOs separate from UI models.
- Store coordinates as neutral latitude/longitude, not provider-specific map objects.
- Use backend-side verification for restricted actions.
- Use backend-side spatial queries for map markers.
- Consider coarse location display for sensitive lost/found listings.
- Keep mock services available for previews, offline UI testing, and screenshot generation.
