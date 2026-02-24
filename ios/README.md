# Race Team IQ – watchOS App

## Add to your iOS project in Xcode

1. Open **mobile/ios/App/App.xcodeproj** in Xcode.
2. **File → New → Target.** Choose **Watch OS → Watch App**. Name: **RaceTeamIQWatch**. Uncheck "Include Notification Scene" if you want to add it later.
3. Delete the default Swift files Xcode created in the new Watch App group.
4. In the Project Navigator, **right‑click the RaceTeamIQWatch group → Add Files to "App"**. Select the **watch-app/ios/RaceTeamIQWatch** folder (or copy its contents into the target’s group). Ensure **RaceTeamIQWatch** target is checked.
5. In the Watch App target’s **Signing & Capabilities**, set your team and bundle ID (e.g. `com.raceteamiq.app.watchkitapp`).
6. Build and run the **App** scheme on a device/simulator with a paired watch; then run the **RaceTeamIQWatch** scheme on the watch.

## Phone side (to sync events to the watch)

The watch uses **WatchConnectivity** to receive `upcomingEvents` and send `adjustStartTime`. The iPhone app (Capacitor) needs a native plugin or code in **AppDelegate** that:

- Calls `getUpcomingEventsForWatch` (or fetches races) and sends the list to the watch via `WCSession.default.updateApplicationContext([WatchMessageKey.upcomingEvents: encodedData])`.
- Listens for `adjustStartTime` messages and updates the race’s `scheduledStartTime` in Firestore.

Until that’s implemented, the watch shows “No upcoming events” until you add the phone-side sync.

## Session recording and offline upload

The watch records sessions (GPS/sensors) and sends them to the phone via **transferUserInfo** so the system can deliver them when the phone is available (works when the watch was offline and reconnects later).

- **Watch:** `PendingSessionStore` persists payloads to `pending_sessions.json`. When the user stops recording, `WatchConnectivityManager.sendSessionPayload` enqueues the payload and calls `transferUserInfo`. On app launch (`activationDidComplete`), any still-pending payloads are re-queued so they are delivered after a restart.
- **Phone (native):** `WatchConnectivitySupport` implements `session(_:didReceive userInfo:)` and appends each received session to `watch_sessions_pending.json`.
- **Phone (JS):** When the user is on the dashboard, `WatchSync` polls and calls `checkPendingSessionAndUpload()`, which reads that file, calls `submitWatchSession` for each payload, then clears the queue.

So the watch can record without the phone; sessions are uploaded once the phone app is open and the watch has reconnected.
