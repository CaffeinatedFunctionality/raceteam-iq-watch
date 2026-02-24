# Race Team IQ – Wear OS App

Kotlin + Jetpack Compose for Wear OS. Shows upcoming events (synced from phone via Data Layer or backend), event detail with **Track This Race** and **Adjust start time**.

## Open in Android Studio

1. **File → Open** and select the **`watch-app/android`** folder.
2. Let Gradle sync. If the Gradle wrapper is missing, use **File → New → New Project → Wear OS** to create a template and copy `gradle/wrapper` into this folder.
3. Run on a Wear OS emulator (e.g. **Wear OS Small Round**) or a physical watch paired with your phone.

## Project structure

- **`app/src/main/java/com/raceteamiq/watch/`**
  - `MainActivity.kt` – Entry; event list (from Data Layer) or placeholder when no events.
  - `WatchDataLayer.kt` – Listens for upcoming events at path `PATH_UPCOMING_EVENTS`; parses JSON into `List<UpcomingEvent>`.
  - `UpcomingEvent.kt` – Data class matching `watch-app/shared/types.ts` (and optional `WatchEventsPayload` with `events` + `canTrack`).
- **PendingSessionStore.kt** – Persists session payloads to `pending_sessions.json` so they can be sent when the phone is connected (offline-first, same idea as iOS).
- **WatchSessionSync.kt** – `flushPendingSessions(context)` sends all pending payloads via **MessageClient** to connected phone node(s) at path `PATH_SUBMIT_SESSION` (`/race_team_iq/submit_session`). Called on app resume so offline sessions sync when the phone reconnects.
- **Next steps:** Event detail screen (weather, start time, **Track This Race**, **Adjust start time**), session recording (then enqueue payload with `PendingSessionStore` and call `flushPendingSessions` on stop).

## Phone app: send events to the watch

The main Android app (`mobile/android`) syncs upcoming events to the watch via the **Wearable Data Layer**:

- **Path:** `WatchDataLayer.PATH_UPCOMING_EVENTS` = `"/race_team_iq/upcoming_events"`
- **Key:** `WatchDataLayer.KEY_PAYLOAD` = `"payload"`
- **Value:** JSON string of `{"events": [...], "canTrack": true}` (same shape as iOS `WatchEventsWrapper`).

The phone uses a custom Capacitor plugin (`WatchSyncPlugin`) that calls `DataClient.putDataItem` with this payload. `WatchSync` in the dashboard layout triggers sync when the user has a team (same as iOS); the watch receives updates and shows the event list.

## Session recording and offline upload

When session recording is implemented, the watch will enqueue payloads with `PendingSessionStore` and send them via **MessageClient** when the phone is connected:

- **Watch:** Store payloads in `PendingSessionStore` when the user stops recording; `flushPendingSessions()` runs on app resume (and can be called after each enqueue) and sends each pending payload to connected node(s) at path `PATH_SUBMIT_SESSION`. The watch can record without the phone; sessions are sent once the phone is connected.
- **Phone (Android):** Implement a **MessageClient** listener for path `WatchSessionSync.PATH_SUBMIT_SESSION` (`/race_team_iq/submit_session`). Message data is the JSON string of the session payload; upload to your backend (e.g. `submitWatchSession`) then acknowledge if needed.

## Icon

Replace `@android:drawable/ic_menu_my_calendar` in `AndroidManifest.xml` with your own `@mipmap/ic_launcher` and add launcher icons under `res/mipmap-*`.
