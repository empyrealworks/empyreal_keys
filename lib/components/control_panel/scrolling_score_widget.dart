// Temporary test code to add to scrolling_score_widget.dart
// Replace the build method temporarily to test quantization

import 'package:empyrealkeys/components/notation/staff_notation_view.dart';
import 'package:flutter/material.dart';
import '../../models/note_event.dart';
import '../../models/recording.dart';

enum ScoreViewMode { pianoRoll, staff }

class ScrollingScoreWidget extends StatefulWidget {
  final Recording recording;
  final double currentPosition;
  final double screenHeight;

  const ScrollingScoreWidget({
    super.key,
    required this.recording,
    required this.currentPosition,
    required this.screenHeight,
  });

  @override
  State<ScrollingScoreWidget> createState() => _ScrollingScoreWidgetState();
}

class _ScrollingScoreWidgetState extends State<ScrollingScoreWidget> {
  ScoreViewMode _viewMode = ScoreViewMode.pianoRoll;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main view
        _viewMode == ScoreViewMode.pianoRoll
            ? _PianoRollView(
                recording: widget.recording,
                currentPosition: widget.currentPosition,
                screenHeight: widget.screenHeight,
              )
            : StaffNotationView(
                recording: widget.recording,
                currentPosition: widget.currentPosition,
                screenHeight: widget.screenHeight,
                scrollMode: NotationScrollMode.vertical,
              ),

        // Floating toggle button in top-right corner
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ViewToggleButton(
                  icon: Icons.piano,
                  label: 'Roll',
                  isSelected: _viewMode == ScoreViewMode.pianoRoll,
                  onTap: () =>
                      setState(() => _viewMode = ScoreViewMode.pianoRoll),
                ),
                _ViewToggleButton(
                  icon: Icons.music_note,
                  label: 'Staff',
                  isSelected: _viewMode == ScoreViewMode.staff,
                  onTap: () => setState(() => _viewMode = ScoreViewMode.staff),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ViewToggleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ViewToggleButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color:
              isSelected ? Theme.of(context).primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Keep your existing _PianoRollView class unchanged
class _PianoRollView extends StatelessWidget {
  final Recording recording;
  final double currentPosition;
  final double screenHeight;

  const _PianoRollView({
    required this.recording,
    required this.currentPosition,
    required this.screenHeight,
  });

  List<NoteBlock> _buildNoteBlocks() {
    final blocks = <NoteBlock>[];
    final Map<int, NoteEvent> activeNotes = {};

    for (final event in recording.events) {
      if (event.type == NoteEventType.on) {
        activeNotes[event.midiNote] = event;
      } else if (event.type == NoteEventType.off) {
        final startEvent = activeNotes.remove(event.midiNote);
        if (startEvent != null) {
          final duration = (event.timestamp.inMilliseconds -
                  startEvent.timestamp.inMilliseconds) /
              1000.0;
          blocks.add(NoteBlock(
            midiNote: startEvent.midiNote,
            startTime: startEvent.timestamp.inMilliseconds / 1000.0,
            duration: duration,
            velocity: startEvent.velocity,
          ));
        }
      }
    }

    return blocks;
  }

  @override
  Widget build(BuildContext context) {
    final notes = _buildNoteBlocks();
    final pixelsPerSecond = 150.0;
    final noteHeight = 8.0;
    final trackHeight = screenHeight * 0.35;

    final pitches = notes.map((n) => n.midiNote).toList();
    final minPitch =
        pitches.isEmpty ? 48 : pitches.reduce((a, b) => a < b ? a : b);
    final maxPitch =
        pitches.isEmpty ? 84 : pitches.reduce((a, b) => a > b ? a : b);
    final pitchRange = (maxPitch - minPitch).clamp(12, 48);
    final pitchSpacing = trackHeight / pitchRange;

    final totalWidth = recording.events.isEmpty
        ? 100.0
        : (recording.events.last.timestamp.inMilliseconds / 1000.0) *
            pixelsPerSecond;

    return Container(
      margin: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: NeverScrollableScrollPhysics(),
              child: Transform.translate(
                offset: Offset(-currentPosition * pixelsPerSecond + 50, 0),
                child: CustomPaint(
                  size: Size(totalWidth + 200, trackHeight),
                  painter: ScorePainter(
                    notes: notes,
                    pixelsPerSecond: pixelsPerSecond,
                    noteHeight: noteHeight,
                    minPitch: minPitch,
                    maxPitch: maxPitch,
                    pitchSpacing: pitchSpacing,
                    currentPosition: currentPosition,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 50,
              top: 0,
              bottom: 0,
              child: Container(
                width: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).primaryColor.withValues(alpha: 0.3),
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withValues(alpha: 0.3),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 20,
                color: Colors.black.withValues(alpha: 0.3),
                child: CustomPaint(
                  painter: TimeMarkerPainter(
                    currentPosition: currentPosition,
                    pixelsPerSecond: pixelsPerSecond,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NoteBlock {
  final int midiNote;
  final double startTime;
  final double duration;
  final int velocity;

  NoteBlock({
    required this.midiNote,
    required this.startTime,
    required this.duration,
    required this.velocity,
  });
}

// Keep your existing painters
class ScorePainter extends CustomPainter {
  final List<NoteBlock> notes;
  final double pixelsPerSecond;
  final double noteHeight;
  final int minPitch;
  final int maxPitch;
  final double pitchSpacing;
  final double currentPosition;

  ScorePainter({
    required this.notes,
    required this.pixelsPerSecond,
    required this.noteHeight,
    required this.minPitch,
    required this.maxPitch,
    required this.pitchSpacing,
    required this.currentPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;

    for (int i = minPitch; i <= maxPitch; i++) {
      final y = (maxPitch - i) * pitchSpacing;
      if (i % 12 == 0) {
        canvas.drawLine(
          Offset(0, y),
          Offset(size.width, y),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.15)
            ..strokeWidth = 1,
        );
      } else {
        canvas.drawLine(
          Offset(0, y),
          Offset(size.width, y),
          linePaint,
        );
      }
    }

    for (final note in notes) {
      final x = note.startTime * pixelsPerSecond;
      final width =
          (note.duration * pixelsPerSecond).clamp(2.0, double.infinity);
      final y = (maxPitch - note.midiNote) * pitchSpacing - noteHeight / 2;

      final isActive = currentPosition >= note.startTime &&
          currentPosition < (note.startTime + note.duration);

      final noteColor = isActive
          ? Color(0xFF00FF00)
          : (note.midiNote % 12 == 1 ||
                  note.midiNote % 12 == 3 ||
                  note.midiNote % 12 == 6 ||
                  note.midiNote % 12 == 8 ||
                  note.midiNote % 12 == 10)
              ? Color(0xFF444444)
              : Color(0xFF2196F3);

      final notePaint = Paint()
        ..color = noteColor
        ..style = PaintingStyle.fill;

      final glowPaint = Paint()
        ..color = noteColor.withValues(alpha: 0.3)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4);

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, width, noteHeight),
        Radius.circular(noteHeight / 2),
      );

      canvas.drawRRect(rect, glowPaint);
      canvas.drawRRect(rect, notePaint);

      if (isActive) {
        canvas.drawRRect(
          rect,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(ScorePainter oldDelegate) => true;
}

class TimeMarkerPainter extends CustomPainter {
  final double currentPosition;
  final double pixelsPerSecond;

  TimeMarkerPainter({
    required this.currentPosition,
    required this.pixelsPerSecond,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    final textStyle = TextStyle(
      color: Colors.white.withValues(alpha: 0.6),
      fontSize: 10,
    );

    textPainter.text = TextSpan(
      text: '${currentPosition.toStringAsFixed(1)}s',
      style: textStyle,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(55, 5));
  }

  @override
  bool shouldRepaint(TimeMarkerPainter oldDelegate) => true;
}
