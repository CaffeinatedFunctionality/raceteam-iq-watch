# Race Team IQ – Watch App Design

## Overview

Companion watch apps (watchOS + Wear OS) for **Race Team IQ** that:
1. **Notify** the user when an event (race) is coming up.
2. **Show event details**: location (track), weather, and **race start time** with “Track This Race” and “Adjust start time.”
3. **Record track-session analytics** (practice or race) for AI-driven insights in the main app.

---

## 1. Analytics to Record via the Watch

Watches can provide the following data. Use what’s available on each platform and align names/formats so the backend and AI see a single “session” model.

### 1.1 Location & speed (GPS)

| Metric | Description | Use for AI |
|--------|-------------|------------|
| **Speed (mph/kph)** | Instantaneous speed from GPS (or fused location). | Corner entry/exit speed, straight speed; compare to “ideal” or prior laps. |
| **Position (lat/lng)** | Sample path at ~1 Hz (or platform default). | Lap detection, segment identification (turn 1, turn 2, etc.), track map. |
| **Altitude** | If available. | Elevation change, e.g. uphill/downhill corners. |
| **Heading** | Direction of travel. | Turn detection, corner classification (left/right). |

**Platform notes:**
- **watchOS:** `CLLocationManager` + `HKWorkoutRouteBuilder` (or HealthKit workout session with route). Derive speed from location deltas or use `CLLocation.speed` when valid.
- **Wear OS:** Fused Location Provider or Health Services (ExerciseClient) for workout sessions; get location/speed in the exercise stream.

### 1.2 Motion (accelerometer / gyro)

| Metric | Description | Use for AI |
|--------|-------------|------------|
| **Lateral G (approximate)** | From accelerometer (watch on wrist). | Relative load in turns; compare left vs right, corner to corner. |
| **Longitudinal G (approximate)** | Braking/acceleration. | Braking intensity, throttle application. |
| **Turn rate / rotation** | From gyro if available. | Sharp vs sweeping corners; consistency. |

Wrist-worn G is not car-level accuracy but useful for **relative** comparison across laps/sessions and for “where was the driver working hardest.”

### 1.3 Heart rate (optional but valuable)

| Metric | Description | Use for AI |
|--------|-------------|------------|
| **Heart rate (bpm)** | Per-second or per-lap average/peak. | Load, stress, consistency; “driver was at 90% HRmax in that stint.” |
| **HR zones / peaks** | E.g. % of session in high HR. | Recovery between sessions, fitness context. |

**Platform notes:**
- **watchOS:** HealthKit (HKWorkoutSession, HKQuantityType.quantityType(forIdentifier: .heartRate)).
- **Wear OS:** Health Services exercise types that include heart rate.

### 1.4 Session start/stop (authoritative)

- **Watch start/stop** (when the driver taps Start/Stop) is **not** the canonical session or lap boundaries. It is used to bound raw GPS/sensor recording only.
- **Authoritative session/lap times** will come from:
  - **MyRacePass** (when integrated), or
  - **Crew member–controlled start/stop** on their watch (e.g. spotter/crew taps Start at green and Stop at checkered). *(TODO: build crew watch flow; do not use driver watch as sole source of truth for session boundaries.)*
- Backend and race view should support overriding or supplementing watch `startTime`/`endTime` with MyRacePass or crew-provided times when available.

### 1.5 Session structure (computed)

| Concept | Description | Use for AI |
|--------|-------------|------------|
| **Lap / segment boundaries** | From GPS (crossing start/finish or geofence), or from MyRacePass/crew. | Lap times, segment times, “lost time in sector 2.” |
| **Where on track** | GPS → map position to track layout (segment, turn, straight). | “What they were doing and where” at each time. |
| **Corner-level aggregates** | Per turn: max speed, avg G, time in corner (if segment detection exists). | “Turn 3: 2 mph slower than last week; consider later brake or different line.” |

### 1.6 Recommended minimum payload per session

Store (and sync to backend) at least:

- **Session metadata:** `sessionId`, `raceId` (link to Race in main app), `startTime`, `endTime`, `devicePlatform` (watchOS | Wear OS).
- **Track identity:** `trackName` (from linked race) or inferred from first GPS bounds.
- **Samples (time series):**
  - `t` (elapsed seconds from session start)
  - `lat`, `lng`, `speed` (mph or m/s), optional `altitude`, `heading`
  - Optional: `heartRate`, `accelX/Y/Z` or derived lateral/longitudinal G
- **Computed (if feasible):** `laps[]` with `lapIndex`, `startTime`, `endTime`, `durationSec`, optional `maxSpeed`, `avgHeartRate`.

AI can then:
- Compare lap-to-lap and session-to-session.
- Relate speed/G in specific corners to setup and conditions.
- Use HR to contextualize driver load and recovery.

---

## 2. Watch UX (aligned for both platforms)

### 2.1 Upcoming events & notifications

- **Sync** from main app (or backend): list of upcoming races (e.g. next 7–14 days) with: `raceId`, `name`, `trackName`, `date`, `scheduledStartTime`, `weather` (summary), optional `location` (lat/lng or address).
- **Notify** the user when an event is “soon” (e.g. 24 h and 1 h before `scheduledStartTime`). Use local notifications (watch) or push (if backend sends to watch/phone).

### 2.2 Event detail screen

- **Tracking is driver-only:** Only users whose team position is **Driver** can use "Track This Race" and submit watch sessions. The phone sends `canTrack: true/false` with events; the watch shows the "Track This Race" button only when `canTrack` is true. The backend rejects `submitWatchSession` for non-drivers.
- **Top:** Event name, track name (location).
- **Middle:** Weather (icon + short text, e.g. “72°F, Clear”).
- **Bottom:** **Race start time** (e.g. “Race starts 2:00 PM”).
- **Actions:**
  - **“Track This Race”** – Start session recording at the **scheduled start time** (or at adjusted time if user changed it). Optionally show a confirmation: “Tracking will start at 2:00 PM.”
  - **“Adjust start time”** – Open a time-picker (or list) to change the race start time; **save back to the main app** (and backend) so the race’s start time is updated everywhere.

So: one source of truth for “when does this race start” (stored on the race in the main app/backend); watch reads it and writes it back when adjusted.

### 2.3 During session

- Simple screen: “Recording …” with elapsed time; optional live speed or HR.
- Stop button to end session; then upload session data to backend and link to `raceId`.

**Offline and reconnection:** The watch can record without the phone. Session payloads are persisted locally (e.g. `PendingSessionStore` on watchOS) and sent via the platform's background transfer (e.g. `transferUserInfo` on iOS). When the phone is available again, the system delivers those payloads; the phone app appends them to a queue file and the main app (JS) uploads them when the user is on the dashboard. On watchOS, after app launch any still-pending sessions are re-queued for delivery so nothing is lost after a restart.

### 2.4 After session

- Optional “Session saved” confirmation.
- Main app shows the session under that race and, in a dedicated **“AI Insights”** block, summarizes what could be improved (car/driver) using the watch analytics plus existing race/setup data.

---

## 3. Shared codebase vs separate

- **Reality:** There is **no single codebase** that builds to both watchOS and Wear OS. They use different languages (Swift vs Kotlin), different APIs (SwiftUI + HealthKit + Core Location vs Compose + Health Services + Fused Location), and different distribution (App Store vs Play Store).
- **Recommended:** **Shared contract, separate implementations.**

  - **Shared (all platforms):**
    - **Data models:** e.g. “Race” (with `scheduledStartTime`), “WatchSession”, “WatchSessionSample”, “UpcomingEvent”. Define in TypeScript/JSON or Kotlin expect/actual so backend and mobile agree; watch apps implement the same shapes.
    - **API contract:** How the main app and watch apps read/write races (including start time), how watch uploads session payloads, how the app fetches “upcoming events” for the watch (or watch fetches via API with auth).
    - **Documentation:** This design, list of metrics, and where AI insights appear.
  - **Separate:** Two native watch projects:
    - **watch-app/ios** – Swift/SwiftUI, watchOS, HealthKit, Core Location, WatchConnectivity to phone (or direct backend if watch has network).
    - **watch-app/android** – Kotlin, Wear OS, Health Services, Fused Location, Data Layer / MessageClient to phone (or direct backend).

So: **shared “what we send and what we show,” separate “how we build the app on each watch platform.”**

---

## 4. Main app changes

### 4.1 Race start time

- Add **`scheduledStartTime`** to the Race model (e.g. optional `string` “HH:mm” in a fixed timezone, or ISO time on the race date). Main app: show it on race detail/edit; allow edit (and sync to backend). Watch: read it for “time the race starts” and “Track This Race”; write it back when user taps “Adjust start time.”

### 4.2 AI Insights for track sessions

- When viewing a **race/event** that has one or more **watch sessions** linked:
  - Add a section, e.g. **“Session insights”** or **“AI Insights”**, that:
    - Shows that watch data is available (e.g. “Session recorded from Apple Watch”).
    - Calls backend (or existing AI flow) with: race + setup + watch session payload (speed/G/HR/laps).
    - Renders AI-generated text: what could be improved for **car and driver** (e.g. “Turn 3 was 2 mph slower than last week; consider later brake or different line,” “Heart rate stayed high after lap 8 – consider cooling or pacing.”).
- Session list can live under the same race (e.g. “Track sessions” with one row per watch recording).

### 4.3 Syncing events to the watch

- **Option A:** Main app (phone) pushes “upcoming events” to the watch via WatchConnectivity (iOS) / Data Layer (Wear OS) when the user opens the app or when events change.
- **Option B:** Watch has a small signed API (or delegates to phone) to fetch “upcoming events” for the current user. Backend endpoint: e.g. `GET /watch/upcoming-events` returning list of events with `scheduledStartTime`, location, weather.

Same contract; different transport (push from phone vs pull from API).

---

## 5. Backend

- **Races:** Support `scheduledStartTime` (read/write). Existing race CRUD continues.
- **Watch sessions:** New collection or subcollection, e.g. `watchSessions` or `races/{raceId}/watchSessions`. Document shape: session metadata + array of samples (and optional laps). Auth: only the team (or race owner) can write/read.
- **AI:** Extend existing AI pipeline to accept a watch session payload and race/setup context; return “insights” text for the main app to show.
- **Notifications:** If you want server-driven reminders, a scheduled function or job that sends “event in 24 h / 1 h” (e.g. via FCM to phone, which can forward to watch, or via a push to watch if supported).

---

## 6. GPS → track position and race view (future)

### 6.1 Where on track (GPS → segment / activity)

- Use **GPS samples** (lat/lng + time) to determine **where on the track** the driver was at each time.
- Goals: map each point to a **track segment** (turn 1, straight, turn 2, etc.) or canonical layout; derive **what they were doing** at each time (e.g. braking into T1, full throttle on straight).
- May use track outline/centerline (per track, from MyRacePass or AI-generated) + point-in-polygon or nearest-segment; or AI/ML to infer segment/activity from path and speed/heading.
- Output: per sample (or window), **segmentId** / **activity** / **phase** so the main app and race view can show “where and what” at any time.

### 6.2 Race view (AI track map + path + activity)

- **Goal:** In the main app, a **race view** where the user sees an **AI-generated (or reference) map of the track**, **where the driver was** over time (path overlay), and **what they were doing at what time** (e.g. “Turn 1 – 87 mph”, “Lap 3, 0:42”).
- **Data:** Watch session samples + GPS→track-position (segment/activity) + optional MyRacePass or crew-provided lap/session times.
- **TODO:** Implement race view UI and track map generation.

### 6.3 TODOs (not built yet)

- **Crew member start/stop:** A crew member (e.g. spotter) controls session start/stop from their watch; those times are the authoritative session boundaries.
- **GPS → track position:** Determine segment/turn/activity and time from GPS; store or compute per sample.
- **Race view:** AI-generated track map + driver path + activity by time.

---

## 7. Summary

| Item | Recommendation |
|------|----------------|
| **Analytics** | GPS (speed, position, heading), motion (G-like), HR; lap/segment when feasible. Store time series + computed laps. |
| **Watch UX** | Event list → event detail (location, weather, start time) → “Track This Race” (start at scheduled/adjusted time) and “Adjust start time” (save to app). |
| **Codebase** | Shared data/API contract and docs; **separate** native watch projects for iOS and Android. |
| **Main app** | Add `scheduledStartTime` to Race; add “AI Insights” for races that have watch session data; sync upcoming events to watch. |
| **Backend** | Store `scheduledStartTime`; watch session storage; session insights; support overriding start/end with MyRacePass or crew when available. |
| **Session start/stop** | Watch start/stop bounds recording only; authoritative times from MyRacePass or crew watch (TODO). |
| **Race view** | AI-generated track map + driver path + activity by time (TODO). |

This gives you a clear path to implement the watch apps and the main-app “AI Insights” using the same analytics and event model across platforms.
