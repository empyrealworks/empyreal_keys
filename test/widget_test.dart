import 'dart:io';

import 'package:empyrealkeys/components/control_panel/scrolling_score_widget.dart';
import 'package:empyrealkeys/components/notation/staff_notation_view.dart';
import 'package:empyrealkeys/components/piano_keyboard/black_keys.dart';
import 'package:empyrealkeys/models/note_event.dart';
import 'package:empyrealkeys/models/recording.dart';
import 'package:empyrealkeys/state/piano_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_music_notation/flutter_music_notation.dart' as fmn;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

Recording _scale() {
  final events = <NoteEvent>[];
  // C major scale, quarter notes at 120 bpm (500 ms each), plus a low C.
  const notes = [60, 62, 64, 65, 67, 69, 71, 72];
  for (var i = 0; i < notes.length; i++) {
    events.add(NoteEvent(
        midiNote: notes[i],
        velocity: 80,
        timestamp: Duration(milliseconds: i * 500),
        type: NoteEventType.on));
    events.add(NoteEvent(
        midiNote: notes[i],
        velocity: 0,
        timestamp: Duration(milliseconds: i * 500 + 480),
        type: NoteEventType.off));
  }
  events.insert(
      0,
      NoteEvent(
          midiNote: 48,
          velocity: 80,
          timestamp: Duration.zero,
          type: NoteEventType.on));
  events.add(NoteEvent(
      midiNote: 48,
      velocity: 0,
      timestamp: const Duration(milliseconds: 1980),
      type: NoteEventType.off));
  events.sort((a, b) => a.timestampMillis.compareTo(b.timestampMillis));
  return Recording(
      id: 'test', title: 'Scale', createdAt: DateTime(2026), events: events);
}

/// Twenty-four bars of the same C-D-E-F quarter notes at 120 bpm, after one silent
/// bar, so every bar holds notes equal to the other bars' notes.
Recording _repeatingTune() {
  final events = <NoteEvent>[];
  const pattern = [60, 62, 64, 65];
  for (var bar = 0; bar < 24; bar++) {
    for (var i = 0; i < 4; i++) {
      final start = 2000 + bar * 2000 + i * 500;
      events.add(NoteEvent(
          midiNote: pattern[i],
          velocity: 80,
          timestamp: Duration(milliseconds: start),
          type: NoteEventType.on));
      events.add(NoteEvent(
          midiNote: pattern[i],
          velocity: 0,
          timestamp: Duration(milliseconds: start + 480),
          type: NoteEventType.off));
    }
  }
  return Recording(
      id: 'tune', title: 'Tune', createdAt: DateTime(2026), events: events);
}

void main() {
  late Directory hiveDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // PianoState listens to connectivity changes; stub the platform side.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('dev.fluttercommunity.plus/connectivity_status'),
            (_) async => null);
    hiveDir = await Directory.systemTemp.createTemp('keys_test');
    Hive.init(hiveDir.path);
    await Hive.openBox('pianoPrefs');
  });

  tearDownAll(() async {
    await Hive.close();
    await hiveDir.delete(recursive: true);
  });

  testWidgets(
      'black keys render while the score is showing on a fresh install',
      (tester) async {
    final pianoState = PianoState();
    await tester.pump();
    pianoState.showScore('Scale', 400);

    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: pianoState,
      child: const MaterialApp(
        home: Scaffold(body: BlackKey(keyWidth: 30, idx: 1)),
      ),
    ));

    expect(tester.takeException(), isNull);
    expect(find.byType(BlackKey), findsOneWidget);
  });

  for (final label in ['Roll', 'Staff']) {
    testWidgets('$label view renders a recording', (tester) async {
      tester.view.physicalSize = const Size(1600, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 400,
            child: ScrollingScoreWidget(
              recording: _scale(),
              currentPosition: 0.5,
              screenHeight: 800,
            ),
          ),
        ),
      ));
      await tester.tap(find.text(label));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('staff view follows playback through a long piece',
      (tester) async {
    tester.view.physicalSize = const Size(800, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final tune = _repeatingTune();

    Future<void> playAt(double seconds) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: StaffNotationView(recording: tune, currentPosition: seconds),
        ),
      ));
      await tester.pump(); // let the post-frame scroll land
    }

    fmn.NotationView view() =>
        tester.widget<fmn.NotationView>(find.byType(fmn.NotationView));
    double scrolled() => tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position
        .pixels;

    // Silence first: the converter drops the empty bar, so nothing plays.
    await playAt(0.5);
    expect(view().config.highlightedMeasure, 1);
    expect(view().playbackController!.activeNotes, isEmpty);
    expect(scrolled(), 0);

    // 2.25 s: bar 1 of the score, first beat, the C.
    await playAt(2.25);
    var active = view().playbackController!.activeNotes;
    expect(view().config.highlightedMeasure, 1);
    expect(active.map((n) => n.pitch.midiNumber), [60]);
    expect(identical(active.single, view().grandStaff!.upperStaff[0].notes.first),
        isTrue);

    // 17.75 s: bar 8, fourth beat, the F, and only bar 8's F lights up.
    await playAt(17.75);
    active = view().playbackController!.activeNotes;
    expect(view().config.highlightedMeasure, 8);
    expect(active.map((n) => n.pitch.midiNumber), [65]);
    final bar8 = view().grandStaff!.upperStaff[7].notes;
    expect(active.every((n) => bar8.any((m) => identical(m, n))), isTrue);
    // Bar 1's F equals bar 8's F but must not light up with it.
    final bar1F = view().grandStaff!.upperStaff[0].notes[3];
    expect(bar1F, equals(active.single));
    expect(active.contains(bar1F), isFalse);
    final deep = scrolled();
    expect(deep, greaterThan(0));

    // Every bar is laid out at full size (the old view squeezed the piece
    // into 2000 px) and the scroll keeps moving forward.
    expect(view().config.width, greaterThan(2000));
    await playAt(19.75);
    expect(view().config.highlightedMeasure, 9);
    expect(scrolled(), greaterThan(deep));
    expect(tester.takeException(), isNull);
  });
}
