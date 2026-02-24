package com.raceteamiq.watch

import android.content.Context
import android.util.Log
import com.google.android.gms.wearable.Wearable
import com.google.gson.Gson
import kotlinx.coroutines.tasks.await
import java.nio.charset.StandardCharsets

/**
 * Path the phone app should listen on to receive session payloads from the watch.
 * Message payload: JSON string of WatchSessionPayload (sessionId, raceId, startTime, endTime, devicePlatform, samples, etc.).
 */
const val PATH_SUBMIT_SESSION = "/race_team_iq/submit_session"

private val gson = Gson()

/**
 * Tries to send all pending session payloads to connected phone node(s).
 * Call after enqueueing a new session (when recording stops) and on app resume so offline sessions sync when the phone reconnects.
 * Does not remove payloads from the store; the phone should acknowledge or the app can remove after a successful send (best-effort).
 */
suspend fun flushPendingSessions(context: Context) {
    val store = PendingSessionStore(context)
    val pending = store.allPending()
    if (pending.isEmpty()) return

    val nodeClient = Wearable.getNodeClient(context)
    val messageClient = Wearable.getMessageClient(context)
    val nodes = nodeClient.connectedNodes.await()
    if (nodes.isEmpty()) {
        Log.d("WatchSessionSync", "No connected nodes; ${pending.size} session(s) will sync when phone is available")
        return
    }

    for (payload in pending) {
        val sessionId = payload["sessionId"]?.toString() ?: continue
        val json = gson.toJson(payload)
        val data = json.toByteArray(StandardCharsets.UTF_8)
        var sent = false
        for (node in nodes) {
            try {
                messageClient.sendMessage(node.id, PATH_SUBMIT_SESSION, data).await()
                sent = true
                store.remove(sessionId)
                break
            } catch (e: Exception) {
                Log.w("WatchSessionSync", "Failed to send session $sessionId to node ${node.displayName}", e)
            }
        }
        if (!sent) {
            Log.d("WatchSessionSync", "Session $sessionId not sent; will retry when phone connects")
        }
    }
}
