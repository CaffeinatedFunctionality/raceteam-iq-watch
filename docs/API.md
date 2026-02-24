# Watch app – API contract

Backend and main app should support the following so both watch apps can integrate the same way.

## 1. Race start time

- **Model:** `Race.scheduledStartTime` optional string, 24h `"HH:mm"` (e.g. `"14:00"`), on the race’s `date`.
- **Read:** Race detail / upcoming-events payload includes `scheduledStartTime`.
- **Write:** Updating a race (from main app or watch “Adjust start time”) can set `scheduledStartTime`; persist in Firestore (or existing race store).

## 2. Upcoming events for the watch

- **Endpoint (optional):** e.g. `GET /watch/upcoming-events` or equivalent (e.g. callable function) returning:
  - `events: UpcomingEvent[]` (see `shared/types.ts`: `raceId`, `name`, `trackName`, `date`, `scheduledStartTime`, `weather`, `location`).
- **Alternative:** Main app pushes the same shape to the watch via WatchConnectivity (iOS) / Data Layer (Wear OS) when the user opens the app or when events change.

## 3. Watch session upload

- **Write:** Watch (or phone on behalf of watch) uploads `WatchSessionPayload` (see `shared/types.ts`).
- **Storage:** e.g. `watchSessions` collection or `races/{raceId}/watchSessions` with document shape = payload + `userId` / `teamId` for auth.
- **Auth:** Only the owning team (or race owner) can create/read; validate token or user from main app.

## 4. AI insights

- **Callable:** `generateSessionInsights({ raceId })` – loads race, setup snapshot, and watch session(s); returns `{ insights: string | null, message?: string }`. If no watch data, returns `message: "No watch session data for this event yet."`
- **Output:** Text summary for “AI Insights” in the main app (e.g. “Turn 3 was 2 mph slower…”, “Heart rate stayed high…”).
- **Storage:** Watch sessions are in `watchSessions` (see section 3). AI reads by `raceId`.

## 5. GPS → track position

- **trackLayouts** collection: document id = slug of track name (e.g. `charlotte-motor-speedway`). Fields: `trackName`, `segments` (array of `{ id, name, polyline: [{ lat, lng }] }`), `updatedAt`.
- **setTrackLayout({ trackName, segments }):** Create/update a track layout (auth required). Segments define polylines; enrichment maps each GPS point to the nearest segment.
- **getTrackLayout({ trackName }):** Return layout for a track (for UI or editing).
- **enrichWatchSessionWithTrackPosition({ sessionId }):** For the given watch session, load its track layout by session’s `trackName`, map each sample (lat, lng) to nearest segment, set `segmentId` and infer `activity` from speed (straight/corner/braking/slow). Updates the session doc in place. Called automatically after session upload; can also be called manually. Requires team membership. 