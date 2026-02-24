//
//  UpcomingEvent.swift
//  Matches watch-app/shared/types.ts UpcomingEvent
//

import Foundation

struct UpcomingEvent: Identifiable, Codable {
  var id: String { raceId }
  let raceId: String
  let name: String
  let trackName: String
  let date: String // YYYY-MM-DD
  let scheduledStartTime: String? // "HH:mm"
  let weather: EventWeather?
  let location: EventLocation?
}

struct EventWeather: Codable {
  let temperature: Double
  let conditions: String
}

struct EventLocation: Codable {
  let lat: Double
  let lng: Double
}
