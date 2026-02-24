/**
 * Shared data contract for Race Team IQ watch apps (watchOS + Wear OS).
 * Keep in sync with mobile/types (Race, etc.) and backend.
 */

/** Race start time on the event date, 24h "HH:mm" (e.g. "14:00"). Timezone is event-local or user preference. */
export type RaceStartTime = string;

export interface UpcomingEvent {
  raceId: string;
  name: string;
  trackName: string;
  date: string; // ISO date YYYY-MM-DD
  scheduledStartTime: RaceStartTime | null; // "HH:mm" or null
  weather?: {
    temperature: number;
    conditions: string;
  };
  location?: { lat: number; lng: number } | null;
}

export interface WatchSessionSample {
  t: number; // elapsed seconds from session start
  lat?: number;
  lng?: number;
  speed?: number; // mph or m/s (document which in backend)
  altitude?: number;
  heading?: number; // degrees
  heartRate?: number;
  accelX?: number;
  accelY?: number;
  accelZ?: number;
  /** Set by backend enrichment: which track segment (e.g. turn 1, back straight). */
  segmentId?: string | null;
  /** Set by backend enrichment: inferred activity (e.g. straight, corner, braking). */
  activity?: string | null;
}

/** One segment of a track (e.g. turn 1, back straight). Polyline in lat/lng. */
export interface TrackSegment {
  id: string;
  name: string;
  polyline: Array<{ lat: number; lng: number }>;
}

/** Track layout for mapping GPS points to segments. Key by track name or slug. */
export interface TrackLayout {
  trackName: string;
  segments: TrackSegment[];
}

export interface WatchSessionLap {
  lapIndex: number;
  startTime: number; // elapsed sec
  endTime: number;
  durationSec: number;
  maxSpeed?: number;
  avgHeartRate?: number;
}

export interface WatchSessionPayload {
  sessionId: string;
  raceId: string;
  /** Watch recording window; authoritative session/lap times may come from MyRacePass or crew-controlled start/stop. */
  startTime: string; // ISO datetime
  endTime: string;
  devicePlatform: 'watchOS' | 'Wear OS';
  trackName?: string;
  samples: WatchSessionSample[];
  laps?: WatchSessionLap[];
}
