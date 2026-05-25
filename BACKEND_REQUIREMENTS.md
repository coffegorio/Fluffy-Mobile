# Fluffy Backend Requirements

This document describes the backend contract Fluffy should grow toward. The iOS app is currently mock-backed, so these requirements can be used as the starting point for API design.

## Principles

- The backend is the source of truth for auth, verification, moderation, listing status, and permissions.
- The client may cache and display state, but must not be trusted for access control.
- API responses should be explicit and stable. Avoid encoding business rules only in display strings.
- Map data should use neutral coordinates and backend-owned identifiers.
- Sensitive locations should support coarse display.

## Auth

Required flows:

- Request sign-in code by email.
- Verify code and return session tokens.
- Refresh access token.
- Sign out / revoke refresh token.

Suggested endpoints:

```http
POST /auth/email-code
POST /auth/verify-code
POST /auth/refresh
POST /auth/logout
```

Session response:

```json
{
  "accessToken": "jwt-or-opaque-token",
  "refreshToken": "refresh-token",
  "expiresAt": "2026-05-25T12:00:00Z",
  "user": {
    "id": "user_123",
    "email": "user@example.com",
    "verificationStatus": "required"
  }
}
```

## User Profile And Verification

The app displays a verification notice in the profile. The backend must decide whether the user has full access.

Suggested statuses:

- `required`
- `pending`
- `verified`
- `rejected`

Suggested endpoints:

```http
GET /me
PATCH /me/profile
GET /me/verification
POST /me/verification/start
POST /me/verification/documents
```

The backend should block restricted actions if the user is not verified, even if the client hides or modifies the local UI.

## Listings

Listings cover lost pets, found pets, rehoming, boarding requests/offers, pet-sitting, and volunteer requests.

Suggested fields:

```json
{
  "id": "listing_123",
  "category": "lost",
  "title": "Lost cat Luna",
  "animalType": "cat",
  "breed": "Scottish Fold",
  "age": "3 years",
  "sex": "female",
  "description": "Last seen near the metro.",
  "location": {
    "city": "Saint Petersburg",
    "district": "Vasileostrovsky",
    "address": "coarse or exact address",
    "latitude": 59.942,
    "longitude": 30.278,
    "precision": "district"
  },
  "media": [
    {
      "id": "media_1",
      "url": "https://cdn.example.com/listings/1.jpg",
      "kind": "image"
    }
  ],
  "tags": ["reward", "microchip"],
  "isUrgent": true,
  "status": "active",
  "moderationStatus": "approved",
  "author": {
    "id": "user_123",
    "name": "Dmitry K.",
    "avatarUrl": "https://cdn.example.com/avatar.jpg",
    "isVerified": true
  },
  "createdAt": "2026-05-25T10:00:00Z",
  "updatedAt": "2026-05-25T10:00:00Z"
}
```

Suggested endpoints:

```http
GET /listings
POST /listings
GET /listings/{id}
PATCH /listings/{id}
POST /listings/{id}/close
POST /listings/{id}/favorite
DELETE /listings/{id}/favorite
```

Filtering should support category, city, viewport, search query, urgency, and pagination.

## Maps

The app should request markers for the visible map area, not download all objects.

Suggested endpoint:

```http
GET /map/markers?northEastLat=55.95&northEastLng=37.95&southWestLat=55.55&southWestLng=37.25&zoom=11&types=lost,found,shelter
```

Response:

```json
{
  "markers": [
    {
      "id": "marker_listing_123",
      "kind": "lost",
      "title": "Lost cat Luna",
      "subtitle": "SPB, Vasileostrovsky",
      "latitude": 59.942,
      "longitude": 30.278,
      "imageUrl": "https://cdn.example.com/listings/123.jpg",
      "isUrgent": true,
      "target": {
        "kind": "listing",
        "id": "listing_123"
      }
    }
  ],
  "clusters": [
    {
      "id": "cluster_55_37",
      "latitude": 55.76,
      "longitude": 37.62,
      "count": 24,
      "dominantKind": "lost"
    }
  ]
}
```

Backend requirements for maps:

- Store latitude and longitude as trusted server fields.
- Use spatial indexes or geohashes for viewport queries.
- Support marker filtering by type and status.
- Return clusters at lower zoom levels.
- Support location precision rules, especially for lost/found pets.
- Hide private exact addresses from users who should not see them.

## Shelters And Pet-Sitters

Shelters and pet-sitters should be separate resources because they have different verification, contact, and moderation rules.

Suggested endpoints:

```http
GET /shelters
GET /shelters/{id}
POST /shelters/{id}/help-requests

GET /pet-sitters
GET /pet-sitters/{id}
POST /pet-sitters/{id}/contact
```

## Chats

Chats should be server-owned and permission-checked.

Suggested endpoints:

```http
GET /conversations
POST /conversations
GET /conversations/{id}/messages
POST /conversations/{id}/messages
POST /conversations/{id}/read
```

Realtime can be added later with WebSockets, Server-Sent Events, or a managed realtime service.

## Media

Use signed upload URLs so the app does not upload large files through the API server.

Suggested flow:

```http
POST /media/upload-url
PUT signed-storage-url
POST /media/complete
```

The backend should validate media ownership, size, MIME type, and moderation status.

## Moderation And Safety

Required capabilities:

- Report listing/user/message.
- Block user.
- Moderation queue for listings and media.
- Server-side restricted action checks.
- Rate limits for auth, listing creation, messages, and reports.

Suggested endpoints:

```http
POST /reports
POST /users/{id}/block
GET /moderation/listings
PATCH /moderation/listings/{id}
```

## Backend Readiness Checklist

- Auth tokens and refresh flow exist.
- `GET /me` returns verification status.
- Listings API supports pagination and filters.
- Map markers API supports viewport and filters.
- Backend enforces verification for restricted actions.
- Media upload uses signed URLs.
- Chats are permission-checked.
- API has error codes the iOS app can map to localized messages.
- Production data never trusts client-provided verification or role flags.
