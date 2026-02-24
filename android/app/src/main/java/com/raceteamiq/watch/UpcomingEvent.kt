package com.raceteamiq.watch

import com.google.gson.annotations.SerializedName

/**
 * Matches watch-app/shared/types.ts UpcomingEvent.
 */
data class UpcomingEvent(
    @SerializedName("raceId") val raceId: String,
    @SerializedName("name") val name: String,
    @SerializedName("trackName") val trackName: String,
    @SerializedName("date") val date: String,
    @SerializedName("scheduledStartTime") val scheduledStartTime: String?,
    @SerializedName("weather") val weather: Weather? = null,
    @SerializedName("location") val location: Location? = null
) {
    data class Weather(
        @SerializedName("temperature") val temperature: Double,
        @SerializedName("conditions") val conditions: String
    )

    data class Location(
        @SerializedName("lat") val lat: Double,
        @SerializedName("lng") val lng: Double
    )
}

/**
 * Payload sent from phone (matches iOS WatchEventsWrapper).
 */
data class WatchEventsPayload(
    @SerializedName("events") val events: List<UpcomingEvent>? = null,
    @SerializedName("canTrack") val canTrack: Boolean? = null
)
