

import 'package:flutter/foundation.dart';
import 'package:flutter_midi_16kb/flutter_midi_16kb.dart';
import '../services/soundfont.dart';

class MidiProvider with ChangeNotifier {
  bool isSoundfontLoaded = false;
  List<String> downloadedSoundfonts = [];

  final SoundfontService soundfontService;

  MidiProvider({required String font, required this.soundfontService}) {
    loadMidi(font); // Initialize the MIDI with the given soundfont
  }

  // Load the soundfont file
  void loadMidi(String font) async {

    // Ensure the soundfont is downloaded or exists locally
    await soundfontService.loadSoundfont(font);

    // Retrieve the local path of the soundfont file
    String localPath = await soundfontService.getSoundfontPath(font);

    // Print list of downloaded soundfonts
    List<String> downloadedSoundfonts = await soundfontService.getListOfLocalSoundfonts();
    this.downloadedSoundfonts = downloadedSoundfonts;

    // Load the soundfont using the local path
    bool success = await FlutterMidi16kb.loadSoundfont(
      localPath, // Use the downloaded file path
    );

    // Update the loaded state and notify listeners
    isSoundfontLoaded = success;
    notifyListeners();
  }

  // Unload the soundfont file
  void unloadMidi() async {
    await FlutterMidi16kb.unloadSoundfont();
    isSoundfontLoaded = false;
    notifyListeners();
  }

  // Play a MIDI note with a specific key and velocity
  void playNote({
    required int midiNote,
    int channel = 0,
    int velocity = 75,
  }) {
    if (isSoundfontLoaded) {
      FlutterMidi16kb.playNote(
        channel: channel,
        key: midiNote,
        velocity: velocity,
      );
    }
  }

  // Stop a playing MIDI note
  void stopNote({
    required int midiNote,
    int channel = 0,
  }) {
    if (isSoundfontLoaded) {
      FlutterMidi16kb.stopNote(
        channel: channel,
        key: midiNote,
      );
    }
  }

  // Stop all playing MIDI notes
  void stopAllNotes() {
    if (isSoundfontLoaded) {
      FlutterMidi16kb.stopAllNotes();
    }
  }
}
