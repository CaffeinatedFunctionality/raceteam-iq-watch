//
//  WatchConnectivityManager.swift
//  Receives upcoming events from phone; sends "adjust start time" back.
//

import Foundation
import WatchConnectivity

private struct WatchEventsWrapper: Codable {
  let events: [UpcomingEvent]?
  let canTrack: Bool?
}

/// Keys for WatchConnectivity message/context
enum WatchMessageKey {
  static let upcomingEvents = "upcomingEvents"
  static let adjustStartTime = "adjustStartTime"
  static let raceId = "raceId"
  static let scheduledStartTime = "scheduledStartTime"
  /// UserInfo key for session payload (transferUserInfo); phone receives this when watch reconnects.
  static let submitSession = "submitSession"
}

final class WatchConnectivityManager: NSObject, ObservableObject {
  static let shared = WatchConnectivityManager()
  @Published var isReachable = false
  @Published var lastReceivedEvents: [UpcomingEvent] = []
  @Published var canTrack: Bool = false
  
  private override init() {
    super.init()
    if WCSession.isSupported() {
      let session = WCSession.default
      session.delegate = self
      session.activate()
    }
  }
  
  func requestEvents() {
    guard WCSession.default.activationState == .activated else { return }
    WCSession.default.sendMessage(
      [WatchMessageKey.upcomingEvents: "request"],
      replyHandler: { [weak self] reply in
        if let data = reply[WatchMessageKey.upcomingEvents] as? Data {
          self?.decodeAndPublishEvents(data: data)
        }
      },
      errorHandler: { _ in }
    )
  }
  
  static let sessionPayloadKey = "submitSession"
  
  /// Sends session to phone. Works offline: payload is saved locally and queued via transferUserInfo
  /// so it is delivered when the watch connects to the phone again.
  func sendSessionPayload(_ payload: [String: Any]) {
    PendingSessionStore.shared.enqueue(payload)
    guard WCSession.default.activationState == .activated else { return }
    // transferUserInfo is queued by the system and delivered when the phone is available (even after app restart).
    let userInfo = [WatchMessageKey.submitSession: payload]
    WCSession.default.transferUserInfo(userInfo)
  }
  
  func sendAdjustStartTime(raceId: String, scheduledStartTime: String) {
    guard WCSession.default.activationState == .activated else { return }
    WCSession.default.sendMessage(
      [
        WatchMessageKey.adjustStartTime: true,
        WatchMessageKey.raceId: raceId,
        WatchMessageKey.scheduledStartTime: scheduledStartTime,
      ],
      replyHandler: nil,
      errorHandler: { _ in }
    )
  }
  
  private func decodeAndPublishEvents(data: Data) {
    let decoder = JSONDecoder()
    if let wrapper = try? decoder.decode(WatchEventsWrapper.self, from: data) {
      DispatchQueue.main.async {
        self.lastReceivedEvents = wrapper.events ?? []
        self.canTrack = wrapper.canTrack ?? false
      }
    } else if let events = try? decoder.decode([UpcomingEvent].self, from: data) {
      DispatchQueue.main.async {
        self.lastReceivedEvents = events
        self.canTrack = false
      }
    }
  }
}

extension WatchConnectivityManager: WCSessionDelegate {
  func session(
    _ session: WCSession,
    activationDidCompleteWith activationState: WCSessionActivationState,
    error: Error?
  ) {
    DispatchQueue.main.async {
      self.isReachable = session.isReachable
      self.flushPendingSessions()
    }
  }
  
  func sessionReachabilityDidChange(_ session: WCSession) {
    DispatchQueue.main.async {
      self.isReachable = session.isReachable
      // Don't flush here: transferUserInfo already queued in sendSessionPayload will be delivered when reachable.
    }
  }
  
  /// Re-queue pending sessions only after activation (e.g. app launch). transferUserInfo from sendSessionPayload is already queued by the system and will be delivered when the phone is available.
  private func flushPendingSessions() {
    guard WCSession.default.activationState == .activated else { return }
    for payload in PendingSessionStore.shared.allPending() {
      let userInfo = [WatchMessageKey.submitSession: payload]
      WCSession.default.transferUserInfo(userInfo)
    }
  }
  
  func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
    if let data = applicationContext[WatchMessageKey.upcomingEvents] as? Data {
      decodeAndPublishEvents(data: data)
    }
  }
  
  func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
    if let data = message[WatchMessageKey.upcomingEvents] as? Data {
      decodeAndPublishEvents(data: data)
    }
  }
  
  func session(_ session: WCSession, didFinish userInfoTransfer: WCSessionUserInfoTransfer) {
    if let payload = userInfoTransfer.userInfo[WatchMessageKey.submitSession] as? [String: Any],
       let sessionId = payload["sessionId"] as? String {
      PendingSessionStore.shared.remove(sessionId: sessionId)
    }
  }
}
