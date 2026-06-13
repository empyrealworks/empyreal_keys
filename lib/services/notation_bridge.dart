// lib/services/notation_bridge.dart

import 'package:flutter_music_notation/flutter_music_notation.dart' as fmn;
import '../models/recording.dart';
import '../models/note_event.dart';

class NotationBridge {
  /// Convert Recording to plugin's MidiData
  static fmn.MidiData recordingToMidiData(Recording recording) {
    final midiNotes = <fmn.MidiNote>[];
    final Map<int, NoteEvent> activeNotes = {};

    // Convert note events to MIDI notes
    for (final event in recording.events) {
      if (event.type == NoteEventType.on) {
        activeNotes[event.midiNote] = event;
      } else if (event.type == NoteEventType.off) {
        final startEvent = activeNotes.remove(event.midiNote);
        if (startEvent != null) {
          midiNotes.add(fmn.MidiNote(
            midiNumber: startEvent.midiNote,
            velocity: startEvent.velocity,
            startTime: startEvent.timestampMillis,
            endTime: event.timestampMillis,
          ));
        }
      }
    }

    return fmn.MidiData(
      notes: midiNotes,
      timeSignatureNumerator: recording.timeSignatureNumerator,
      timeSignatureDenominator: recording.timeSignatureDenominator,
      keySignatureSharps: recording.keySignatureSharps,
      keySignatureIsMinor: recording.keySignatureIsMinor,
      beatsPerMinute: recording.beatsPerMinute,
      ticksPerQuarterNote: recording.ticksPerQuarterNote,
    );
  }

  /// Convert MidiData to grand staff measures
  static fmn.GrandStaff midiDataToGrandStaff(fmn.MidiData midiData) {
    final converter = fmn.MidiToNotation(midiData: midiData);
    return converter.toGrandStaff();
  }

  /// Convert MidiData to single staff measures
  static List<fmn.Measure> midiDataToMeasures(
      fmn.MidiData midiData, {
        fmn.ClefPreference clef = fmn.ClefPreference.auto,
      }) {
    final converter = fmn.MidiToNotation(midiData: midiData);
    return converter.toSingleStaff(clefPreference: clef);
  }
}