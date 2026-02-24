//
//  PendingSessionStore.swift
//  Persists session payloads so they can be sent when the watch reconnects to the phone.
//

import Foundation

/// Stores session payloads to disk so recording works offline and uploads when connected.
final class PendingSessionStore {
  static let shared = PendingSessionStore()
  
  private let fileManager = FileManager.default
  private let queueKey = "pendingSessions"
  
  private var pendingFileURL: URL? {
    guard let dir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
    return dir.appendingPathComponent("pending_sessions.json", isDirectory: false)
  }
  
  private init() {}
  
  /// Append a session payload (same shape as sent to phone) for later transfer.
  func enqueue(_ payload: [String: Any]) {
    guard let url = pendingFileURL else { return }
    var list = loadPending(from: url)
    list.append(payload)
    savePending(list, to: url)
  }
  
  /// Remove the payload with the given sessionId from the queue.
  func remove(sessionId: String) {
    guard let url = pendingFileURL else { return }
    var list = loadPending(from: url)
    list.removeAll { ($0["sessionId"] as? String) == sessionId }
    savePending(list, to: url)
  }
  
  /// All pending payloads (e.g. to re-submit on activation).
  func allPending() -> [[String: Any]] {
    guard let url = pendingFileURL else { return [] }
    return loadPending(from: url)
  }
  
  /// Remove all pending (e.g. after successful transfer).
  func removeAll() {
    guard let url = pendingFileURL else { return }
    savePending([], to: url)
  }
  
  private func loadPending(from url: URL) -> [[String: Any]] {
    guard fileManager.fileExists(atPath: url.path),
          let data = try? Data(contentsOf: url),
          let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
      return []
    }
    return json
  }
  
  private func savePending(_ list: [[String: Any]], to url: URL) {
    guard let data = try? JSONSerialization.data(withJSONObject: list) else { return }
    try? data.write(to: url)
  }
}
