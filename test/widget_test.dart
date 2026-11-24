import 'dart:io';

import 'package:empyrealkeys/components/control_panel/scrolling_score_widget.dart';
import 'package:empyrealkeys/components/piano_keyboard/black_keys.dart';
import 'package:empyrealkeys/models/note_event.dart';
import 'package:empyrealkeys/models/recording.dart';
import 'package:empyrealkeys/state/piano_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
}
