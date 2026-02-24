//
//  EventDetailView.swift
//

import SwiftUI

struct EventDetailView: View {
  let event: UpcomingEvent
  @EnvironmentObject var eventsManager: WatchEventsManager
  @StateObject private var recorder = SessionRecorder()
  @State private var showAdjustTime = false
  @State private var showRecording = false
  
  private var startTimeText: String {
    guard let t = event.scheduledStartTime, !t.isEmpty else { return "Start time not set" }
    let parts = t.split(separator: ":")
    if parts.count >= 2, let h = Int(parts[0]), let m = Int(parts[1]) {
      let hour = h % 12 == 0 ? 12 : h % 12
      let ampm = h < 12 ? "AM" : "PM"
      return "Race starts \(hour):\(String(format: "%02d", m)) \(ampm)"
    }
    return "Starts \(t)"
  }
  
  var body: some View {
    List {
      Section("Location") {
        Text(event.trackName)
      }
      if let w = event.weather {
        Section("Weather") {
          Text("\(Int(w.temperature))°F, \(w.conditions)")
        }
      }
      Section {
        Text(startTimeText).font(.subheadline)
      }
      Section {
        if eventsManager.canTrack {
          Button("Track This Race") {
            recorder.start(raceId: event.raceId, trackName: event.trackName)
            showRecording = true
          }
        }
        Button("Adjust start time") { showAdjustTime = true }
      }
    }
    .navigationTitle(event.name)
    .sheet(isPresented: $showAdjustTime) {
      AdjustStartTimeView(event: event)
    }
    .sheet(isPresented: $showRecording) {
      SessionRecordingView(event: event, recorder: recorder)
    }
  }
}
