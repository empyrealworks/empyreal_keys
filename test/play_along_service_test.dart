import 'package:empyrealkeys/models/note_event.dart';
import 'package:empyrealkeys/models/recording.dart';
import 'package:empyrealkeys/services/play_along_service.dart';
import 'package:flutter_test/flutter_test.dart';

Recording _piece() => Recording(
      id: 'p',
      title: 'P',
      createdAt: DateTime(2026),
      events: [
        for (var i = 0; i < 20; i++) ...[
          NoteEvent(
              midiNote: 60,
              velocity: 80,
              timestamp: Duration(milliseconds: i * 1000),
              type: NoteEventType.on),
          NoteEvent(
              midiNote: 60,
              velocity: 0,
              timestamp: Duration(milliseconds: i * 1000 + 900),
              type: NoteEventType.off),
        ],
      ],
    );

void main() {
  late PlayAlongService service;

  setUp(() {
    service = PlayAlongService()..loadPiece(_piece());
  });
  tearDown(() => service.stopPlayback());

  Future<void> play() => service.startPlayback(
        onNoteOn: (_) {},
        onNoteOff: (_) {},
      );

  Future<void> wait() => Future.delayed(const Duration(milliseconds: 120));

  test('playback starts from where it was seeked to', () async {
    service.seekTo(5);
    await play();
    await wait();
    expect(service.playbackPosition, inInclusiveRange(5.0, 5.6));
  });

  test('seeking while playing carries on from the new position', () async {
    await play();
    await wait();
    service.seekTo(10);
    await wait();
    expect(service.playbackPosition, inInclusiveRange(10.0, 10.6));
  });

  test('resuming after a pause carries on from where it paused', () async {
    await play();
    await wait();
    service.pausePlayback();
    final pausedAt = service.playbackPosition;
    await wait();
    service.resumePlayback();
    await wait();
    expect(service.playbackPosition,
        inInclusiveRange(pausedAt, pausedAt + 0.6));
  });

  test('changing tempo does not make the position jump', () async {
    service.seekTo(8);
    await play();
    await wait();
    final before = service.playbackPosition;
    service.setTempoMultiplier(1.5);
    await wait();
    expect(service.playbackPosition, inInclusiveRange(before, before + 0.6));
  });
}
