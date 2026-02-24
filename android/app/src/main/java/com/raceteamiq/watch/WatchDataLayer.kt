package com.raceteamiq.watch

import android.content.Context
import android.util.Log
import com.google.android.gms.wearable.DataClient
import com.google.android.gms.wearable.DataEvent
import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.DataMapItem
import com.google.android.gms.wearable.Wearable
import com.google.gson.Gson
import com.google.gson.JsonSyntaxException
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.callbackFlow

/**
 * Path the phone app must use when sending upcoming events via DataClient.
 * Keep in sync with mobile Android app (when implemented).
 */
const val PATH_UPCOMING_EVENTS = "/race_team_iq/upcoming_events"

/** Key for JSON payload in DataMap (phone sends dataMap.putString(KEY_PAYLOAD, json)). */
const val KEY_PAYLOAD = "payload"

private val gson = Gson()

/**
 * Observes the Wear Data Layer for upcoming events from the phone.
 * Emits the list whenever the data at [PATH_UPCOMING_EVENTS] changes.
 */
fun DataClient.upcomingEventsFlow(context: Context) = callbackFlow {
    val listener = DataClient.OnDataChangedListener { dataEvents: DataEventBuffer ->
        for (i in 0 until dataEvents.count) {
            val event = dataEvents.get(i)
            if (event.type != DataEvent.TYPE_CHANGED) continue
            if (event.dataItem.uri.path != PATH_UPCOMING_EVENTS) continue
            try {
                val json = DataMapItem.fromDataItem(event.dataItem).dataMap.getString(KEY_PAYLOAD)
                    ?: continue
                val payload = gson.fromJson(json, WatchEventsPayload::class.java)
                trySend(payload.events ?: emptyList())
            } catch (e: JsonSyntaxException) {
                Log.e("WatchDataLayer", "Failed to parse upcoming events", e)
            } catch (e: Exception) {
                Log.e("WatchDataLayer", "Error reading events", e)
            }
        }
    }

    addListener(listener)
    awaitClose { removeListener(listener) }
}
