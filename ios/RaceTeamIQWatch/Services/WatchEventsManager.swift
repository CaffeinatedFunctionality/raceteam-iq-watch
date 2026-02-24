//
//  WatchEventsManager.swift
//

import Foundation
import WatchConnectivity

final class WatchEventsManager: ObservableObject {
  @Published var events: [UpcomingEvent] = []
  @Published var canTrack: Bool = false
  @Published var isLoading = false
  
  private let connectivity = WatchConnectivityManager.shared
  
  init() {
    connectivity.$lastReceivedEvents
      .receive(on: DispatchQueue.main)
      .assign(to: &$events)
    connectivity.$canTrack
      .receive(on: DispatchQueue.main)
      .assign(to: &$canTrack)
  }
  
  func refresh() {
    isLoading = true
    connectivity.requestEvents()
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
      self?.isLoading = false
    }
  }
}
