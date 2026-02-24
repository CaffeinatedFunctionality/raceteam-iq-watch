package com.raceteamiq.watch

import android.content.Context
import android.util.Log
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import java.io.File
import java.lang.reflect.Type

private const val PENDING_FILE = "pending_sessions.json"
private val listType: Type = object : TypeToken<List<Map<String, Any?>>>() {}.type
private val gson = Gson()

/**
 * Persists session payloads so they can be sent to the phone when connected.
 * Same idea as iOS PendingSessionStore: enqueue when recording stops, remove when delivery is confirmed.
 */
class PendingSessionStore(context: Context) {
    private val file = File(context.filesDir, PENDING_FILE)

    fun enqueue(payload: Map<String, Any?>) {
        val list = allPending().toMutableList()
        list.add(payload)
        save(list)
    }

    fun remove(sessionId: String) {
        val list = allPending().filter { it["sessionId"] != sessionId }
        save(list)
    }

    fun allPending(): List<Map<String, Any?>> {
        if (!file.exists()) return emptyList()
        return try {
            val json = file.readText()
            gson.fromJson<List<Map<String, Any?>>>(json, listType) ?: emptyList()
        } catch (e: Exception) {
            Log.e("PendingSessionStore", "Failed to read pending sessions", e)
            emptyList()
        }
    }

    fun removeAll() {
        save(emptyList())
    }

    private fun save(list: List<Map<String, Any?>>) {
        try {
            file.writeText(gson.toJson(list))
        } catch (e: Exception) {
            Log.e("PendingSessionStore", "Failed to save pending sessions", e)
        }
    }
}
