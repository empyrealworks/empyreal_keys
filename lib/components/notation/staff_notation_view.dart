// components/notation/staff_notation_view.dart

import 'dart:collection';
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
  final _playhead = _PlayheadController();

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
      _score = _Score.build(widget.recording, _config);
    }
    _followPlayback();
  }

  /// Highlights what is sounding now and scrolls the playhead into place
  /// once this frame is laid out.
  void _followPlayback() {
    final at = _score.locate(widget.currentPosition);
    _playhead.show(at == null ? const {} : _score.notesSounding(at));
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollTo(at));
  }

  void _scrollTo(_ScorePoint? at) {
    if (!mounted || at == null || !_scrollController.hasClients) return;
    final position = _scrollController.position;
    final target = _config.padding.left +
        _score.xAt(at) -
        _viewportWidth * StaffNotationView.playheadFraction;
    final clamped = target.clamp(0.0, position.maxScrollExtent);
    if ((clamped - position.pixels).abs() > 0.5) {
      _scrollController.jumpTo(clamped);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _playhead.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final at = _score.locate(widget.currentPosition);
    final config = _config.copyWith(
      width: _score.viewWidth,
      highlightedMeasure: at == null ? null : at.bar + 1,
      clearHighlight: at == null,
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
                    playbackController: _playhead,
                    config: config,
                  ),
                  if (at != null)
                    Positioned(
                      left: _config.padding.left + _score.xAt(at) - 1,
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

/// A point in the score: a bar (0-based) and a beat within it.
class _ScorePoint {
  final int bar;
  final double beat;
  const _ScorePoint(this.bar, this.beat);
}

/// The engraved piece plus its single-line layout, used to map playback time
/// to bars, beats and x positions.
class _Score {
  final fmn.GrandStaff grandStaff;
  final fmn.GrandStaffSystemInfo? line;

  /// Width to give [fmn.NotationView], padding included.
  final double viewWidth;
  final double staffTop;
  final double staffBottom;
  final double beatsPerSecond;
  final double barLength;

  /// Beats removed before bar 1 (whole bars of silence before the first note).
  final double leadingShift;

  _Score._({
    required this.grandStaff,
    required this.line,
    required this.viewWidth,
    required this.staffTop,
    required this.staffBottom,
    required this.beatsPerSecond,
    required this.barLength,
    required this.leadingShift,
  });

  factory _Score.build(Recording recording, fmn.NotationConfig config) {
    final midiData = NotationBridge.recordingToMidiData(recording);
    final grandStaff = NotationBridge.midiDataToGrandStaff(midiData);
    final beatsPerSecond = recording.beatsPerMinute / 60.0;
    final barLength = recording.timeSignatureNumerator *
        4.0 /
        recording.timeSignatureDenominator;

    // The package never compresses bars, so lay the line out at no width to
    // get its natural length, then give the view exactly that much room.
    // Bars squeezed into a narrower view would run off its end.
    final natural = fmn.GrandStaffLayout.forConfig(grandStaff, config, 0);
    final naturalLine =
        natural.systems.isEmpty ? null : natural.systems.first;
    final pageWidth = naturalLine == null
        ? 0.0
        : naturalLine.spacing.measureSpacings.last.endX + config.rightMargin;
    final layout = fmn.GrandStaffLayout.forConfig(grandStaff, config, pageWidth);
    final line = layout.systems.isEmpty ? null : layout.systems.first;
    final staffHeight = config.staffSpaceSize * 4;

    // The converter drops whole empty bars before the first note. Work out
    // how many from where the first note landed in bar 1; rounding absorbs
    // the small nudge quantizing gives it.
    var shift = 0.0;
    final firstOn = midiData.notes.isEmpty
        ? null
        : midiData.notes.map((n) => n.startTime).reduce(math.min);
    if (firstOn != null && grandStaff.measureCount > 0) {
      final barOne = [
        ...grandStaff.upperStaff.first.notes,
        ...grandStaff.lowerStaff.first.notes,
      ];
      if (barOne.isNotEmpty) {
        final firstInBar = barOne.map((n) => n.startBeat).reduce(math.min);
        final raw = firstOn / 1000.0 * beatsPerSecond;
        shift = ((raw - firstInBar) / barLength).round() * barLength;
        if (shift < 0) shift = 0;
      }
    }

    return _Score._(
      grandStaff: grandStaff,
      line: line,
      viewWidth: pageWidth + config.padding.horizontal,
      staffTop: line?.upperStaffY ?? 0,
      staffBottom: (line?.lowerStaffY ?? 0) + staffHeight,
      beatsPerSecond: beatsPerSecond,
      barLength: barLength,
      leadingShift: shift,
    );
  }

  /// The bar and beat playing at [seconds] into the recording, or null when
  /// there is nothing to show.
  _ScorePoint? locate(double seconds) {
    final bars = grandStaff.measureCount;
    if (line == null || bars == 0) return null;
    final total = bars * barLength;
    final beat = seconds * beatsPerSecond - leadingShift;
    // Silence before the first bar: wait at the start with nothing lit.
    if (beat < 0) return const _ScorePoint(0, -1);
    final bar = math.min((math.min(beat, total) / barLength).floor(), bars - 1);
    return _ScorePoint(bar, beat - bar * barLength);
  }

  /// The notes sounding at [at], as the very objects in the score (several
  /// bars can hold notes that compare equal).
  Set<fmn.Note> notesSounding(_ScorePoint at) {
    final sounding = HashSet<fmn.Note>.identity();
    for (final staff in [grandStaff.upperStaff, grandStaff.lowerStaff]) {
      for (final note in staff[at.bar].notes) {
        if (note.startBeat <= at.beat + 1e-6 && note.endBeat > at.beat + 1e-6) {
          sounding.add(note);
        }
      }
    }
    return sounding;
  }

  /// Where [at] falls on the line, moving evenly from one note column to the
  /// next and from the last column to the barline.
  double xAt(_ScorePoint at) {
    final spacing = line!.spacing.measureSpacings[at.bar];
    final beats = at.bar < line!.spacingBeats.length
        ? line!.spacingBeats[at.bar]
        : const <double>[];
    final xs = spacing.positions;
    final n = math.min(beats.length, xs.length);

    // Anchors: each column, then the bar's end at the barline.
    var prevBeat = 0.0;
    var prevX = n > 0 ? xs[0] : spacing.startX;
    if (n > 0 && beats[0] > 0) {
      // A bar starting with silence: run from the bar's start to column 1.
      prevX = spacing.startX;
    }
    for (var i = 0; i < n; i++) {
      if (at.beat < beats[i]) {
        return _lerp(prevBeat, prevX, beats[i], xs[i], at.beat);
      }
      prevBeat = beats[i];
      prevX = xs[i];
    }
    // Glide on into the next bar's first column rather than jumping the gap
    // between bars at the barline.
    final measures = line!.spacing.measureSpacings;
    final next = at.bar + 1 < measures.length ? measures[at.bar + 1] : null;
    final nextStartsOnBeat = at.bar + 1 < line!.spacingBeats.length &&
        line!.spacingBeats[at.bar + 1].isNotEmpty &&
        line!.spacingBeats[at.bar + 1].first <= 1e-6;
    final endX = next != null && nextStartsOnBeat && next.positions.isNotEmpty
        ? next.positions.first
        : (next?.startX ?? spacing.endX);
    return _lerp(prevBeat, prevX, barLength, endX, at.beat);
  }

  static double _lerp(double b0, double x0, double b1, double x1, double b) {
    if (b1 - b0 <= 1e-9) return x0;
    return x0 + (x1 - x0) * ((b - b0) / (b1 - b0)).clamp(0.0, 1.0);
  }
}

/// Feeds [fmn.NotationView] the notes to highlight. The package's own
/// controller compares notes by value and times them from the start of the
/// piece, while the converter's notes are timed from the start of each bar,
/// so the view's highlighting is driven from [_Score] instead.
class _PlayheadController extends fmn.PlaybackController {
  _PlayheadController() : super(notes: const []);

  Set<fmn.Note> _sounding = HashSet<fmn.Note>.identity();

  @override
  Set<fmn.Note> get activeNotes => UnmodifiableSetView(_sounding);

  /// Called while the score widget rebuilds, so it does not notify: the
  /// view reads [activeNotes] as part of the same build.
  void show(Set<fmn.Note> notes) => _sounding = notes;
}
