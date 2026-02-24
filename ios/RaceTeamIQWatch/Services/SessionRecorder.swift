//
//  SessionRecorder.swift
//  Records location + motion + optional heart rate for watch session; builds payload to send to phone.
//

import Foundation
import CoreLocation
import CoreMotion

struct SessionSample: Codable {
  let t: Double
  let lat: Double?
  let lng: Double?
  let speed: Double?
  let altitude: Double?
  let heading: Double?
  let heartRate: Double?
  let accelX: Double?
  let accelY: Double?
  let accelZ: Double?
}

final class SessionRecorder: NSObject, ObservableObject {
  @Published var isRecording = false
  @Published var elapsedSeconds: Int = 0
  @Published var sampleCount: Int = 0
  @Published var lastSpeed: Double?
  
  private var startDate: Date?
  private var samples: [SessionSample] = []
  private let locationManager = CLLocationManager()
  private var timer: Timer?
  private let motionManager = CMMotionManager()
  private var latestMotion: CMDeviceMotion?
  private let motionQueue = OperationQueue()
  private var latestHeartRate: Double?

  override init() {
    super.init()
    locationManager.delegate = self
    locationManager.desiredAccuracy = kCLLocationAccuracyBest
    locationManager.distanceFilter = 5
    motionQueue.maxConcurrentOperationCount = 1
  }

  func start(raceId: String, trackName: String) {
    guard !isRecording else { return }
    currentRaceId = raceId
    currentTrackName = trackName
    startDate = Date()
    samples = []
    elapsedSeconds = 0
    sampleCount = 0
    lastSpeed = nil
    latestMotion = nil
    latestHeartRate = nil
    locationManager.requestWhenInUseAuthorization()
    locationManager.startUpdatingLocation()
    if motionManager.isDeviceMotionAvailable {
      motionManager.deviceMotionUpdateInterval = 0.1
      motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: motionQueue) { [weak self] motion, _ in
        self?.latestMotion = motion
      }
    }
    startHeartRateQueries()
    isRecording = true
    timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
      self?.elapsedSeconds = Int(Date().timeIntervalSince(self?.startDate ?? Date()))
    }
  }

  private var currentRaceId = ""
  private var currentTrackName = ""

  func stop() -> (raceId: String, trackName: String, startTime: Date, endTime: Date, samples: [SessionSample])? {
    guard isRecording, let start = startDate else { return nil }
    timer?.invalidate()
    timer = nil
    locationManager.stopUpdatingLocation()
    motionManager.stopDeviceMotionUpdates()
    stopHeartRateQueries()
    isRecording = false
    let end = Date()
    return (currentRaceId, currentTrackName, start, end, samples)
  }

  private func startHeartRateQueries() {
    // Optional: add HealthKit capability, then stream heart rate into latestHeartRate.
    // See DESIGN.md for HealthKit workout/HR notes.
  }

  private func stopHeartRateQueries() {
    // stopHeartRateObserving() if you added HealthKit
  }

  private func sampleWith(loc: CLLocation, start: Date) -> SessionSample {
    let t = loc.timestamp.timeIntervalSince(start)
    let speed = loc.speed >= 0 ? loc.speed * 2.23694 : nil
    let altitude = loc.altitude.isFinite ? loc.altitude : nil
    let course = loc.course >= 0 ? loc.course : nil
    var accelX: Double?, accelY: Double?, accelZ: Double?
    if let motion = latestMotion {
      let a = motion.userAcceleration
      accelX = a.x; accelY = a.y; accelZ = a.z
    }
    return SessionSample(
      t: t,
      lat: loc.coordinate.latitude,
      lng: loc.coordinate.longitude,
      speed: speed,
      altitude: altitude,
      heading: course,
      heartRate: latestHeartRate,
      accelX: accelX,
      accelY: accelY,
      accelZ: accelZ
    )
  }
}

extension SessionRecorder: CLLocationManagerDelegate {
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let start = startDate, let loc = locations.last, loc.horizontalAccuracy >= 0 else { return }
    let sample = sampleWith(loc: loc, start: start)
    samples.append(sample)
    sampleCount = samples.count
    DispatchQueue.main.async { [weak self] in
      self?.lastSpeed = sample.speed
    }
  }
}
