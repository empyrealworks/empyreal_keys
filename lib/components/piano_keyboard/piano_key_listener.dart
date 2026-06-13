// piano_key_listener.dart

import 'dart:math';

import 'package:empyrealkeys/state/recorder_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/midi_provider.dart';
import '../../state/piano_state.dart';

class PianoKeyListener extends StatefulWidget {
  final Widget child;
  final List<int> whiteKeyIndices;
  final List<int> blackKeyIndices;
  final List<double> blackKeyOffsets;
  final double whiteKeyWidth;
  final double blackKeyWidth;
  final int numberOfKeys;

  const PianoKeyListener({
    super.key,
    required this.child,
    required this.whiteKeyIndices,
    required this.blackKeyIndices,
    required this.blackKeyOffsets,
    required this.whiteKeyWidth,
    required this.blackKeyWidth,
    required this.numberOfKeys,
  });

  @override
  State<PianoKeyListener> createState() => _PianoKeyListenerState();
}

class _PianoKeyListenerState extends State<PianoKeyListener> {
  // Track the root note for each pointer
  final Map<int, int> _rootNoteByPointer = {};
  // Track all MIDI notes (including chords) started by each pointer
  final Map<int, Set<int>> _activeNotesByPointer = {};

  void _updatePianoState() {
    final allPressed = _activeNotesByPointer.values.expand((e) => e).toSet();
    Provider.of<PianoState>(context, listen: false).setPressedNotes(allPressed);
  }

  Set<int> _playNoteOrChord(int midiNote) {
    final pianoState = Provider.of<PianoState>(context, listen: false);
    final midiProvider = Provider.of<MidiProvider>(context, listen: false);
    final recorder = context.read<RecorderService>();
    final volume = pianoState.volume;
    final isChordMode = pianoState.isChordMode;
    final chordFormulas = pianoState.chordFormulas;
    final chordType = pianoState.chordType;

    Set<int> notesToPlay = {};
    if (isChordMode) {
      List<int> intervals = chordFormulas[chordType] ?? [0];
      for (int interval in intervals) {
        notesToPlay.add(midiNote + interval);
      }
    } else {
      notesToPlay.add(midiNote);
    }

    for (int note in notesToPlay) {
      midiProvider.playNote(midiNote: note, velocity: volume);
      if (recorder.isRecording) {
        recorder.recordNoteOn(note, volume);
      }
    }
    return notesToPlay;
  }

  void _stopNotes(Set<int> notes) {
    final midiProvider = Provider.of<MidiProvider>(context, listen: false);
    final recorder = context.read<RecorderService>();

    for (int note in notes) {
      midiProvider.stopNote(midiNote: note);
      if (recorder.isRecording) {
        recorder.recordNoteOff(note);
      }
    }
  }

  int? _getMidiNoteAt(Offset localPosition, Size size) {
    final pianoState = Provider.of<PianoState>(context, listen: false);
    final octave = pianoState.octave;
    final double keyWidth = size.width / widget.numberOfKeys;
    final double keyHeight = size.height;

    // Check black keys first
    final int blackCount = min(widget.blackKeyIndices.length, widget.blackKeyOffsets.length);
    for (int i = 0; i < blackCount; i++) {
      final double keyLeft = widget.whiteKeyWidth * widget.blackKeyOffsets[i];
      final double keyRight = keyLeft + widget.blackKeyWidth;
      final double keyTop = 0;
      final double keyBottom = keyHeight * 0.6;

      if (localPosition.dx >= keyLeft &&
          localPosition.dx <= keyRight &&
          localPosition.dy >= keyTop &&
          localPosition.dy <= keyBottom) {
        return 12 + (octave * 12) + widget.blackKeyIndices[i];
      }
    }

    // Check white keys
    for (int i = 0; i < widget.whiteKeyIndices.length; i++) {
      final double keyLeft = i * keyWidth;
      final double keyRight = (i + 1) * keyWidth;
      if (localPosition.dx >= keyLeft &&
          localPosition.dx < keyRight &&
          localPosition.dy >= 0 &&
          localPosition.dy <= keyHeight) {
        return 12 + (octave * 12) + widget.whiteKeyIndices[i];
      }
    }
    return null;
  }

  void _onPointerDown(PointerDownEvent details) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset localPosition = box.globalToLocal(details.position);
    final int? midiNote = _getMidiNoteAt(localPosition, box.size);

    if (midiNote != null) {
      _rootNoteByPointer[details.pointer] = midiNote;
      final notes = _playNoteOrChord(midiNote);
      _activeNotesByPointer[details.pointer] = notes;
      
      final pianoState = Provider.of<PianoState>(context, listen: false);
      pianoState.setCurrentNote(pianoState.notes[midiNote % 12]);
      _updatePianoState();
    }
  }

  void _onPointerMove(PointerMoveEvent details) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset localPosition = box.globalToLocal(details.position);
    final int? midiNote = _getMidiNoteAt(localPosition, box.size);

    final int? lastRootNote = _rootNoteByPointer[details.pointer];
    if (midiNote != lastRootNote) {
      // Stop old notes
      final oldNotes = _activeNotesByPointer.remove(details.pointer);
      if (oldNotes != null) {
        _stopNotes(oldNotes);
      }

      if (midiNote != null) {
        _rootNoteByPointer[details.pointer] = midiNote;
        final newNotes = _playNoteOrChord(midiNote);
        _activeNotesByPointer[details.pointer] = newNotes;
        
        final pianoState = Provider.of<PianoState>(context, listen: false);
        pianoState.setCurrentNote(pianoState.notes[midiNote % 12]);
      } else {
        _rootNoteByPointer.remove(details.pointer);
      }
      _updatePianoState();
    }
  }

  void _onPointerUpOrCancel(PointerEvent details) {
    _rootNoteByPointer.remove(details.pointer);
    final notes = _activeNotesByPointer.remove(details.pointer);
    if (notes != null) {
      _stopNotes(notes);
    }
    
    if (_activeNotesByPointer.isEmpty) {
      Provider.of<PianoState>(context, listen: false).setCurrentNote('..');
    }
    _updatePianoState();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUpOrCancel,
      onPointerCancel: _onPointerUpOrCancel,
      child: widget.child,
    );
  }
}
