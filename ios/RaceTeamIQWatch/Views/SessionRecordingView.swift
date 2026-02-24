//
//  SessionRecordingView.swift
//

import SwiftUI

struct SessionRecordingView: View {
  let event: UpcomingEvent
  @ObservedObject var recorder: SessionRecorder
  @Environment(\.dismiss) var dismiss
  
  private var statusLine: String {
    var parts = ["\(recorder.elapsedSeconds)s", "\(recorder.sampleCount) pts"]
    if let mph = recorder.lastSpeed {
      parts.append(String(format: "%.0f mph", mph))
    }
    return parts.joined(separator: " · ")
  }

  var body: some View {
    VStack(spacing: 8) {
      Text("Recording…").font(.headline)
      Text(statusLine).font(.caption)
      Button("Stop") {
        if let result = recorder.stop() {
          sendSessionToPhone(raceId: result.raceId, trackName: result.trackName, start: result.startTime, end: result.endTime, samples: result.samples)
        }
        dismiss()
      }
      .buttonStyle(.borderedProminent)
    }
    .padding()
  }
  
  private func sendSessionToPhone(raceId: String, trackName: String, start: Date, end: Date, samples: [SessionSample]) {
    let payload: [[String: Any]] = samples.map { s in
      var d: [String: Any] = ["t": s.t]
      if let x = s.lat { d["lat"] = x }
      if let x = s.lng { d["lng"] = x }
      if let x = s.speed { d["speed"] = x }
      if let x = s.altitude { d["altitude"] = x }
      if let x = s.heading { d["heading"] = x }
      if let x = s.heartRate { d["heartRate"] = x }
      if let x = s.accelX { d["accelX"] = x }
      if let x = s.accelY { d["accelY"] = x }
      if let x = s.accelZ { d["accelZ"] = x }
      return d
    }
    let sessionId = UUID().uuidString
    let dict: [String: Any] = [
      "sessionId": sessionId,
      "raceId": raceId,
      "startTime": ISO8601DateFormatter().string(from: start),
      "endTime": ISO8601DateFormatter().string(from: end),
      "devicePlatform": "watchOS",
      "trackName": trackName,
      "samples": payload,
    ]
    WatchConnectivityManager.shared.sendSessionPayload(dict)
  }
}
