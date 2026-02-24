//
//  ContentView.swift
//

import SwiftUI

struct ContentView: View {
  @EnvironmentObject var eventsManager: WatchEventsManager
  
  var body: some View {
    Group {
      if eventsManager.events.isEmpty && !eventsManager.isLoading {
        VStack(spacing: 4) {
          Text("No upcoming events")
            .font(.caption)
          Text("Open Race Team IQ on your phone to sync")
            .font(.caption2)
            .multilineTextAlignment(.center)
        }
        .padding()
      } else if eventsManager.isLoading {
        ProgressView("Loading…")
      } else {
        List(eventsManager.events) { event in
          NavigationLink(destination: EventDetailView(event: event)) {
            VStack(alignment: .leading, spacing: 2) {
              Text(event.name).font(.headline)
              Text(event.trackName).font(.caption)
              Text(event.date).font(.caption2)
            }
          }
        }
      }
    }
    .navigationTitle("Races")
    .onAppear { eventsManager.refresh() }
  }
}
