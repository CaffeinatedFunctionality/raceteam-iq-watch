//
//  RaceTeamIQWatchApp.swift
//  Race Team IQ Watch Companion
//

import SwiftUI

@main
struct RaceTeamIQWatchApp: App {
  @StateObject private var eventsManager = WatchEventsManager()
  
  var body: some Scene {
    WindowGroup {
      NavigationStack {
        ContentView()
          .environmentObject(eventsManager)
      }
    }
  }
}
