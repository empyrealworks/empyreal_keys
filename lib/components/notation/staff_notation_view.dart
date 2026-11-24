// components/notation/staff_notation_view.dart

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_music_notation/flutter_music_notation.dart' as fmn;
import '../../models/recording.dart';
import '../../services/notation_bridge.dart';

/// The whole piece on one horizontal line of grand staff. As the music plays
/// it scrolls to keep a playhead about a third of the way across the view,
/// shades the bar being played and highlights the notes sounding.
class StaffNotationView extends StatefulWidget {
  final Recording recording;

  /// Playback position, in seconds of the recording.
  final double currentPosition;

  /// Where the playhead sits, as a fraction of the view's width.
  static const playheadFraction = 0.3;

  const StaffNotationView({
    super.key,
    required this.recording,
    required this.currentPosition,
  });

  @override
  State<StaffNotationView> createState() => _StaffNotationViewState();
}

class _StaffNotationViewState extends State<StaffNotationView> {
  final ScrollController _scrollController = ScrollController();

  late _Score _score;
  double _viewportWidth = 0;

  static const _config = fmn.NotationConfig(
    staffSpaceSize: 8, // Compact
    leftMargin: 120,
    measureSpacing: 25,
    useSystemLayout: false,
    showMeasureNumbers: true,
    showBrace: true,
    grandStaffGap: 30,
    upperStaffHeight: 25,
    lowerStaffHeight: 25,
    enableBeaming: false,
    enableTieDetection: false,
    spacingEngine: fmn.SpacingPresets.uniform,
    showKeySignatureOnEachSystem: true,
  );

  @override
  void initState() {
    super.initState();
    _score = _Score.build(widget.recording, _config);
    _followPlayback();
  }

  @override
  void didUpdateWidget(StaffNotationView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.recording != widget.recording) {
      _score.playback.dispose();
      _score = _Score.build(widget.recording, _config);
    }
    _followPlayback();
  }

  /// Moves the score's playback to the current time (which highlights the
  /// notes sounding) and scrolls the playhead into place once this frame is
  /// laid out.
  void _followPlayback() {
    _score.seekToSeconds(widget.currentPosition);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToPlayhead());
  }

  void _scrollToPlayhead() {
    if (!mounted || !_score.hasLine || !_scrollController.hasClients) return;
    final position = _scrollController.position;
    final target = _config.padding.left +
        _score.playheadX() -
        _viewportWidth * StaffNotationView.playheadFraction;
    final clamped = target.clamp(0.0, position.maxScrollExtent);
    if ((clamped - position.pixels).abs() > 0.5) {
      _scrollController.jumpTo(clamped);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _score.playback.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bar = _score.playback.currentMeasureNumber;
    final config = _config.copyWith(
      width: _score.viewWidth,
      highlightedMeasure: bar,
      clearHighlight: bar == null,
    );

    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withAlpha(76)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: LayoutBuilder(builder: (context, constraints) {
          _viewportWidth = constraints.maxWidth;
          return SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            child: SizedBox(
              width: _score.viewWidth,
              child: Stack(
                children: [
                  fmn.NotationView(
                    grandStaff: _score.grandStaff,
                    playbackController: _score.playback,
                    config: config,
                  ),
                  if (_score.hasLine)
                    Positioned(
                      left: _config.padding.left + _score.playheadX() - 1,
                      top: _config.padding.top + _score.staffTop,
                      height: _score.staffBottom - _score.staffTop,
                      width: 2,
                      child: IgnorePointer(
                        child: ColoredBox(
                          color: Theme.of(context)
                              .primaryColor
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// The engraved piece, its playback controller and its single-line layout,
/// used to map the playback position to an x position for the playhead.
class _Score {
  final fmn.GrandStaff grandStaff;
  final fmn.PlaybackController playback;
  final fmn.GrandStaffSystemInfo? line;

  /// Width to give [fmn.NotationView], padding included.
  final double viewWidth;
  final double staffTop;
  final double staffBottom;
  final double beatsPerSecond;
  final double barLength;

  /// Beats of silence the converter left out before bar 1.
  final double droppedBeats;

  _Score._({
    required this.grandStaff,
    required this.playback,
    required this.line,
    required this.viewWidth,
    required this.staffTop,
    required this.staffBottom,
    required this.beatsPerSecond,
    required this.barLength,
    required this.droppedBeats,
  });

  factory _Score.build(Recording recording, fmn.NotationConfig config) {
    final converter = fmn.MidiToNotation(
      midiData: NotationBridge.recordingToMidiData(recording),
    );
    final grandStaff = converter.toGrandStaff();

    // The package never compresses bars, so lay the line out at no width to
    // get its natural length, then give the view exactly that much room.
    // Bars squeezed into a narrower view would run off its end.
    final natural = fmn.GrandStaffLayout.forConfig(grandStaff, config, 0);
    final pageWidth = natural.systems.isEmpty
        ? 0.0
        : natural.systems.first.spacing.measureSpacings.last.endX +
            config.rightMargin;
    final layout =
        fmn.GrandStaffLayout.forConfig(grandStaff, config, pageWidth);
    final line = layout.systems.isEmpty ? null : layout.systems.first;

    return _Score._(
      grandStaff: grandStaff,
      playback: fmn.PlaybackController.forGrandStaff(
        grandStaff,
        beatsPerMinute: recording.beatsPerMinute,
      ),
      line: line,
      viewWidth: pageWidth + config.padding.horizontal,
      staffTop: line?.upperStaffY ?? 0,
      staffBottom: (line?.lowerStaffY ?? 0) + config.staffSpaceSize * 4,
      beatsPerSecond: recording.beatsPerMinute / 60.0,
      barLength: recording.timeSignatureNumerator *
          4.0 /
          recording.timeSignatureDenominator,
      droppedBeats: converter.droppedLeadingBeats(),
    );
  }

  bool get hasLine => line != null && grandStaff.measureCount > 0;

  /// Moves [playback] to [seconds] into the recording. During the silence
  /// before bar 1 it waits at the start with nothing lit.
  void seekToSeconds(double seconds) {
    final beat = seconds * beatsPerSecond - droppedBeats;
    if (beat < 0) {
      if (playback.position != 0 || playback.activeNotes.isNotEmpty) {
        playback.stop();
      }
    } else if (beat != playback.position) {
      playback.seekTo(beat);
    }
  }

  /// Where the playback position falls on the line, moving evenly from one
  /// note column to the next.
  double playheadX() {
    final bars = grandStaff.measureCount;
    final position = playback.position;
    final bar = math.min((position / barLength).floor(), bars - 1);
    final beat = position - bar * barLength;

    final measures = line!.spacing.measureSpacings;
    final spacing = measures[bar];
    final beats =
        bar < line!.spacingBeats.length ? line!.spacingBeats[bar] : <double>[];
    final xs = spacing.positions;
    final n = math.min(beats.length, xs.length);

    // Anchors: each column, then the next bar's first note.
    var prevBeat = 0.0;
    // A bar starting with silence runs from the bar's start to column 1.
    var prevX = n > 0 && beats[0] <= 0 ? xs[0] : spacing.startX;
    for (var i = 0; i < n; i++) {
      if (beat < beats[i]) return _lerp(prevBeat, prevX, beats[i], xs[i], beat);
      prevBeat = beats[i];
      prevX = xs[i];
    }

    // Glide on into the next bar's first column rather than jumping the gap
    // between bars at the barline.
    final next = bar + 1 < measures.length ? measures[bar + 1] : null;
    final nextStartsOnBeat = bar + 1 < line!.spacingBeats.length &&
        line!.spacingBeats[bar + 1].isNotEmpty &&
        line!.spacingBeats[bar + 1].first <= 1e-6;
    final endX = next != null && nextStartsOnBeat && next.positions.isNotEmpty
        ? next.positions.first
        : (next?.startX ?? spacing.endX);
    return _lerp(prevBeat, prevX, barLength, endX, beat);
  }

  static double _lerp(double b0, double x0, double b1, double x1, double b) {
    if (b1 - b0 <= 1e-9) return x0;
    return x0 + (x1 - x0) * ((b - b0) / (b1 - b0)).clamp(0.0, 1.0);
  }
}
