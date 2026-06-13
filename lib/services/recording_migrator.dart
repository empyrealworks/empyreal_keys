// services/recording_migrator.dart
// Helper to migrate old recordings to new format with metadata

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/recording.dart';
import '../models/note_event.dart';

class RecordingMigrator {
  /// Check if a recording needs migration (has default metadata values)
  static bool needsMigration(Recording recording) {
    // Check if fields exist and have non-default values
    // If timeSignatureNumerator is 4 and keySignatureSharps is 0 and not minor,
    // it might be default or might be actual C major. We'll infer to be safe.
    return true; // For safety, always try to enrich metadata
  }

  /// Migrate a recording by inferring its metadata
  static Recording migrate(Recording recording) {
    if (recording.events.isEmpty) {
      // Can't infer from empty recording, return with defaults
      return recording.copyWith(
        timeSignatureNumerator: 4,
        timeSignatureDenominator: 4,
        keySignatureSharps: 0,
        keySignatureIsMinor: false,
        beatsPerMinute: 120.0,
        ticksPerQuarterNote: 480,
      );
    }

    // Infer key signature
    final keySignature = _inferKeySignature(recording.events);

    // Infer tempo from inter-onset intervals
    final tempo = _inferTempo(recording.events);

    // Infer time signature (this is harder, default to 4/4)
    final timeSignature = _inferTimeSignature(recording.events, tempo);

    return recording.copyWith(
      timeSignatureNumerator: timeSignature.numerator,
      timeSignatureDenominator: timeSignature.denominator,
      keySignatureSharps: keySignature.sharps,
      keySignatureIsMinor: keySignature.isMinor,
      beatsPerMinute: tempo,
      ticksPerQuarterNote: recording.ticksPerQuarterNote,
    );
  }

  /// Infer key signature from note content
  static ({int sharps, bool isMinor}) _inferKeySignature(List<NoteEvent> events) {
    final pitchClassCounts = List<int>.filled(12, 0);

    for (final event in events) {
      if (event.type == NoteEventType.on) {
        final pitchClass = event.midiNote % 12;
        pitchClassCounts[pitchClass]++;
      }
    }

    const majorProfile = [
      6.35, 2.23, 3.48, 2.33, 4.38, 4.09, 2.52, 5.19, 2.39, 3.66, 2.29, 2.88
    ];
    const minorProfile = [
      6.33, 2.68, 3.52, 5.38, 2.60, 3.53, 2.54, 4.75, 3.98, 2.69, 3.34, 3.17
    ];

    double maxCorrelation = -1.0;
    int bestKey = 0;
    bool bestIsMinor = false;

    for (int key = 0; key < 12; key++) {
      final majorCorr = _calculateCorrelation(
          pitchClassCounts,
          _rotateProfile(majorProfile, key)
      );

      final minorCorr = _calculateCorrelation(
          pitchClassCounts,
          _rotateProfile(minorProfile, key)
      );

      if (majorCorr > maxCorrelation) {
        maxCorrelation = majorCorr;
        bestKey = key;
        bestIsMinor = false;
      }

      if (minorCorr > maxCorrelation) {
        maxCorrelation = minorCorr;
        bestKey = key;
        bestIsMinor = true;
      }
    }

    final sharpsCount = _pitchClassToSharps(bestKey, bestIsMinor);
    return (sharps: sharpsCount, isMinor: bestIsMinor);
  }

  /// Infer tempo from inter-onset intervals
  static double _inferTempo(List<NoteEvent> events) {
    if (events.length < 10) return 120.0;

    final intervals = <int>[];
    NoteEvent? lastNoteOn;

    for (final event in events) {
      if (event.type == NoteEventType.on) {
        if (lastNoteOn != null) {
          intervals.add(event.timestampMillis - lastNoteOn.timestampMillis);
        }
        lastNoteOn = event;
      }
    }

    if (intervals.isEmpty) return 120.0;

    intervals.sort();
    final medianInterval = intervals[intervals.length ~/ 2];

    // Convert to BPM
    final bpm = 60000.0 / medianInterval;
    return bpm.clamp(40.0, 240.0);
  }

  /// Infer time signature (simplified - mostly returns 4/4)
  static ({int numerator, int denominator}) _inferTimeSignature(
      List<NoteEvent> events,
      double bpm,
      ) {
    // This is a complex problem. For now, return 4/4 as default
    // In the future, could analyze strong/weak beat patterns

    // Could check if notes cluster into groups of 3 (3/4, 6/8) or 4 (4/4, 2/4)
    // For simplicity, default to 4/4
    return (numerator: 4, denominator: 4);
  }

  static double _calculateCorrelation(List<int> counts, List<double> profile) {
    final countMean = counts.reduce((a, b) => a + b) / counts.length;
    final profileMean = profile.reduce((a, b) => a + b) / profile.length;

    double numerator = 0.0;
    double denomCount = 0.0;
    double denomProfile = 0.0;

    for (int i = 0; i < counts.length; i++) {
      final countDiff = counts[i] - countMean;
      final profileDiff = profile[i] - profileMean;

      numerator += countDiff * profileDiff;
      denomCount += countDiff * countDiff;
      denomProfile += profileDiff * profileDiff;
    }

    if (denomCount == 0 || denomProfile == 0) return 0.0;
    return numerator / (denomCount * denomProfile).abs();
  }

  static List<double> _rotateProfile(List<double> profile, int amount) {
    final rotated = List<double>.filled(profile.length, 0);
    for (int i = 0; i < profile.length; i++) {
      rotated[i] = profile[(i - amount) % profile.length];
    }
    return rotated;
  }

  static int _pitchClassToSharps(int pitchClass, bool isMinor) {
    if (isMinor) {
      const minorSharps = {
        9: 0, 4: 1, 11: 2, 6: 3, 1: 4, 8: 5, 3: 6,
        10: -2, 5: -4, 0: -3, 7: -2, 2: -1,
      };
      return minorSharps[pitchClass] ?? 0;
    } else {
      const majorSharps = {
        0: 0, 7: 1, 2: 2, 9: 3, 4: 4, 11: 5, 6: 6,
        1: -5, 8: -4, 3: -3, 10: -2, 5: -1,
      };
      return majorSharps[pitchClass] ?? 0;
    }
  }

  /// Migrate all recordings in a box
  static Future<void> migrateAllRecordings(Box<Recording> box) async {
    if (kDebugMode) {
      print('Starting recording migration...');
    }
    int migratedCount = 0;

    for (var key in box.keys) {
      final recording = box.get(key);
      if (recording != null) {
        final migrated = migrate(recording);
        await box.put(key, migrated);
        migratedCount++;
      }
    }

    if (kDebugMode) {
      print('Migration complete. Migrated $migratedCount recordings.');
    }
  }
}