// services/playalong_service.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/note_event.dart';
import '../models/recording.dart';

class PlayAlongService with ChangeNotifier {
  Recording? _currentPiece;
  bool _isPlaying = false;
  bool _isPaused = false;
  double _playbackPosition = 0.0; // in seconds
  double _tempoMultiplier = 1.0; // 0.5 to 1.5
  Timer? _playbackTimer;
  // The clock: position = _basePosition + time since _playbackStartTime
  // (scaled by tempo). Every seek, loop, resume or tempo change restarts it
  // from the current position.
  DateTime? _playbackStartTime;
  double _basePosition = 0.0;
  int _currentEventIndex = 0;

  // Loop controls
  double? _loopStart;
  double? _loopEnd;

  // Getters
  Recording? get currentPiece => _currentPiece;
  bool get isPlaying => _isPlaying;
  bool get isPaused => _isPaused;
  double get playbackPosition => _playbackPosition;
  double get tempoMultiplier => _tempoMultiplier;
  double? get loopStart => _loopStart;
  double? get loopEnd => _loopEnd;

  double get totalDuration {
    if (_currentPiece == null || _currentPiece!.events.isEmpty) return 0.0;
    return _currentPiece!.events.last.timestamp.inMilliseconds / 1000.0;
  }

  // Load a piece for playalong
  void loadPiece(Recording piece) {
    stopPlayback();
    _currentPiece = piece;
    _playbackPosition = 0.0;
    _currentEventIndex = 0;
    notifyListeners();
  }

  // Set tempo multiplier (0.5 = 50% speed, 1.5 = 150% speed)
  void setTempoMultiplier(double multiplier) {
    final wasPlaying = _isPlaying && !_isPaused;
    if (wasPlaying) pausePlayback();

    _tempoMultiplier = multiplier.clamp(0.5, 1.5);

    if (wasPlaying) resumePlayback();
    notifyListeners();
  }

  // Set loop region
  void setLoopRegion(double? start, double? end) {
    _loopStart = start;
    _loopEnd = end;
    notifyListeners();
  }

  // Clear loop region
  void clearLoopRegion() {
    _loopStart = null;
    _loopEnd = null;
    notifyListeners();
  }

  // Callback for piano state updates
  Function(Set<int>)? onActiveNotesChanged;

  // Start playback
  Future<void> startPlayback({
    required Function(NoteEvent) onNoteOn,
    required Function(NoteEvent) onNoteOff,
    Function(Set<int>)? onActiveNotesChanged,
  }) async {
    if (_currentPiece == null || _currentPiece!.events.isEmpty) return;

    this.onActiveNotesChanged = onActiveNotesChanged;
    _isPlaying = true;
    _isPaused = false;
    _restartClock(_playbackPosition);

    // Find starting event index based on playback position
    _currentEventIndex = _findEventIndexAtPosition(_playbackPosition);

    notifyListeners();

    _scheduleEvents(onNoteOn, onNoteOff);
  }

  void _scheduleEvents(
      Function(NoteEvent) onNoteOn,
      Function(NoteEvent) onNoteOff,
      ) {
    _playbackTimer?.cancel();

    final Set<int> activeNotes = {};

    _playbackTimer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      if (!_isPlaying || _isPaused) return;

      final elapsed = DateTime.now().difference(_playbackStartTime!).inMilliseconds;
      _playbackPosition = _basePosition + elapsed * _tempoMultiplier / 1000.0;

      // Check loop boundaries
      if (_loopEnd != null && _playbackPosition >= _loopEnd!) {
        _playbackPosition = _loopStart ?? 0.0;
        _currentEventIndex = _findEventIndexAtPosition(_playbackPosition);
        _restartClock(_playbackPosition);
        activeNotes.clear();
        onActiveNotesChanged?.call(activeNotes);
        notifyListeners();
        return;
      }

      // Play events at current position
      bool notesChanged = false;
      while (_currentEventIndex < _currentPiece!.events.length) {
        final event = _currentPiece!.events[_currentEventIndex];
        final eventTime = event.timestamp.inMilliseconds / 1000.0;

        if (eventTime <= _playbackPosition) {
          if (event.type == NoteEventType.on) {
            onNoteOn(event);
            activeNotes.add(event.midiNote);
            notesChanged = true;
          } else {
            onNoteOff(event);
            activeNotes.remove(event.midiNote);
            notesChanged = true;
          }
          _currentEventIndex++;
        } else {
          break;
        }
      }

      if (notesChanged) {
        onActiveNotesChanged?.call(Set.from(activeNotes));
      }

      // Check if playback finished
      if (_currentEventIndex >= _currentPiece!.events.length) {
        if (_loopStart != null || _currentPiece!.loopPlayback) {
          _playbackPosition = _loopStart ?? 0.0;
          _currentEventIndex = _findEventIndexAtPosition(_playbackPosition);
          _restartClock(_playbackPosition);
          activeNotes.clear();
          onActiveNotesChanged?.call(activeNotes);
        } else {
          stopPlayback();
        }
      }

      notifyListeners();
    });
  }

  void pausePlayback() {
    if (!_isPlaying || _isPaused) return;
    _isPaused = true;

    // turn off all currently active notes
    onActiveNotesChanged?.call({});
    notifyListeners();
  }

  void resumePlayback() {
    if (!_isPlaying || !_isPaused) return;
    _isPaused = false;
    _restartClock(_playbackPosition);
    notifyListeners();
  }

  // Stop playback
  void stopPlayback() {
    _playbackTimer?.cancel();
    _isPlaying = false;
    _isPaused = false;
    _playbackPosition = 0.0;
    _currentEventIndex = 0;
    _playbackStartTime = null;
    _basePosition = 0.0;

    // Clear active notes
    onActiveNotesChanged?.call({});
    notifyListeners();
  }

  // Seek to position
  void seekTo(double position) {
    _playbackPosition = position.clamp(0.0, totalDuration);
    _currentEventIndex = _findEventIndexAtPosition(_playbackPosition);

    if (_isPlaying) _restartClock(_playbackPosition);

    notifyListeners();
  }

  void _restartClock(double from) {
    _basePosition = from;
    _playbackStartTime = DateTime.now();
  }

  // Find event index at given position
  int _findEventIndexAtPosition(double position) {
    final positionMs = (position * 1000).round();

    for (int i = 0; i < _currentPiece!.events.length; i++) {
      if (_currentPiece!.events[i].timestamp.inMilliseconds >= positionMs) {
        return i;
      }
    }

    return _currentPiece!.events.length;
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }
}