# Race Team IQ – Watch Apps

Companion watch apps for **Race Team IQ** (watchOS + Wear OS): event reminders, event detail (location, weather, start time), “Track This Race” with adjustable start time, and session analytics for AI insights in the main app.

## Docs

- **[Design & analytics](docs/DESIGN.md)** – Analytics to record, watch UX, shared vs separate codebase, main app and backend changes.

## Structure

- **`shared/`** – Data contract (types, API shape) shared by both watch apps and the main app/backend.
- **`ios/`** – Native watchOS app (Swift, SwiftUI). Companion to the main iOS app.
- **`android/`** – Native Wear OS app (Kotlin). Companion to the main Android app.

There is **no single codebase** that builds to both watchOS and Wear OS; the two native projects share the same **data and API contract** (see `shared/types.ts` and the design doc).

## Features (target)

1. **Notifications** – Notify when an event is coming up (e.g. 24 h and 1 h before start).
2. **Event detail** – Show event name, track (location), weather, and **race start time** at the bottom.
3. **Track This Race** – Start session recording at the race’s scheduled start time (or user-adjusted time).
4. **Adjust start time** – Change race start time on the watch; save back to the main app (and backend).
5. **Session recording** – Record GPS (speed, position), motion (G-like), optional heart rate; upload to backend and link to the race.
6. **AI Insights** – Main app shows “Session insights” / “AI Insights” when viewing a race that has watch session data.

## Getting started

- **watchOS:** The app source is in **`ios/RaceTeamIQWatch/`**. Add it as a **Watch App** target to your existing iOS project (`mobile/ios/App/App.xcodeproj`). See **[ios/README.md](ios/README.md)** for step-by-step instructions. The watch shows upcoming events (from the phone via WatchConnectivity), event detail (location, weather, start time), **Track This Race**, and **Adjust start time**.
- **Wear OS:** Open **`android/`** in Android Studio and run on a Wear OS emulator or device. See **[android/README.md](android/README.md)**. The app currently shows a placeholder; add Data Layer sync from the phone app and the same event-detail UI as on watchOS.

Use **`shared/types.ts`** so both platforms send the same session payload and consume the same upcoming-event shape.

## Deploying the Wear OS app (supplement to the main app)

The Wear OS app is built and deployed by CI as a **separate app** on Google Play, then linked to the main Race Team IQ app as a companion so users see it as a supplement.

### Pipeline

- **Workflow:** `.github/workflows/build-android.yml` (in this repo)
- **Triggers:** Push or PR to `qa` / `master`.
- **On PR:** Builds a debug APK and uploads it as an artifact (no store upload).
- **On push to `qa`:** Builds a signed release AAB and uploads to the **internal** testing track (draft).
- **On push to `master`:** Builds a signed release AAB and uploads to the **production** track.

### Play Console setup

1. **Create the watch app listing** (if you haven’t already):
   - In [Google Play Console](https://play.google.com/console), create a new app (e.g. “Race Team IQ Watch”).
   - Use package name **`com.raceteamiq.watch`** (must match `applicationId` in `android/app/build.gradle.kts`).

2. **Sign the watch app with the same key as the phone app (recommended):**  
   Use the same keystore and secrets as the main Android app (`ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`) in the **QA** and **PROD** environments. The workflow uses these to sign the watch AAB.

3. **Service account for uploads:**
   - Either reuse the main app’s Play service account: add it to the **watch app** in Play Console (Users and permissions → Invite user → select the service account, grant “Release to production” / “Release apps to testing tracks”).
   - Or create a dedicated secret **`PLAY_STORE_WATCH_SERVICE_ACCOUNT_JSON`** for the watch app; the workflow uses it if set, otherwise falls back to **`PLAY_STORE_SERVICE_ACCOUNT_JSON`**.

4. **Link as companion (supplement):**
   - In the **main** app’s Play Console listing (Race Team IQ, phone), open **Release** → **App bundle explorer** (or the equivalent for “Device catalog” / “Form factors”).
   - Add and link the Wear OS app so the store shows the watch app as a companion. Exact steps depend on the current Console UI; typically you associate the Wear OS package or enable “Companion app” / “Wear OS” for the main app so users are prompted to install the watch app when they use the phone app with a watch.

After that, pushing to `qa` or `master` will build the watch app and deploy it to the correct track; you can then roll out or promote the release from Play Console as needed.
