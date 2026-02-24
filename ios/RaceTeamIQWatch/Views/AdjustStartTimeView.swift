//
//  AdjustStartTimeView.swift
//

import SwiftUI

struct AdjustStartTimeView: View {
  let event: UpcomingEvent
  @Environment(\.dismiss) var dismiss
  @State private var selectedTime: Date
  
  init(event: UpcomingEvent) {
    self.event = event
    let d: Date
    if let t = event.scheduledStartTime, let idx = t.firstIndex(of: ":"),
       let h = Int(t[..<idx]), let m = Int(t[t.index(after: idx)...]) {
      var c = Calendar.current.dateComponents([.year, .month, .day], from: Date())
      c.hour = h
      c.minute = m
      d = Calendar.current.date(from: c) ?? Date()
    } else {
      d = Date()
    }
    _selectedTime = State(initialValue: d)
  }
  
  private var timeString: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    return formatter.string(from: selectedTime)
  }
  
  var body: some View {
    VStack(spacing: 8) {
      Text("Race start time").font(.headline)
      DatePicker("Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
        .labelsHidden()
      Button("Save") {
        WatchConnectivityManager.shared.sendAdjustStartTime(raceId: event.raceId, scheduledStartTime: timeString)
        dismiss()
      }
      .buttonStyle(.borderedProminent)
    }
    .padding()
  }
}
