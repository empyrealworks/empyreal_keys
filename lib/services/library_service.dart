// services/library_service.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'dart:io';
import '../models/recording.dart';
import 'midi_parser.dart';

class LibraryService {
  static const String _boxName = 'musicLibrary';
  late Box<Recording> _libraryBox;

  // Preloaded library pieces (asset paths)
  static const Map<String, Map<String, String>> libraryPieces = {
    'Easy': {
      'Mary Had a Little Lamb': 'assets/midi/easy/mary.mid',
      'Twinkle Twinkle': 'assets/midi/easy/twinkle.mid',
      'Ode to Joy': 'assets/midi/easy/ode_to_joy.mid',
      'Jingle Bells': 'assets/midi/easy/jingle_bells.mid',
      'Hot Cross Buns': 'assets/midi/easy/hot_cross_buns.mid',
      'London Bridge': 'assets/midi/easy/london_bridge.mid',
      'When the saints': 'assets/midi/easy/saints.mid',
      'Row Row Row Your Boat': 'assets/midi/easy/row_row.mid',
    },
    'Intermediate': {
      'Canon in D (excerpt)': 'assets/midi/intermediate/canon_full.mid',
      'Fur Elise (section)': 'assets/midi/intermediate/fur_elise.mid',
      'Lean on Me': 'assets/midi/intermediate/lean_on_me.mid',
      'Minuet in G (Bach)': 'assets/midi/intermediate/minuet.mid',
      'Scarborough Fair': 'assets/midi/intermediate/scarborough.mid',
      'Greensleeves': 'assets/midi/intermediate/greensleeves.mid',
      'Somewhere Over the Rainbow': 'assets/midi/intermediate/rainbow.mid',
      'The Four Seasons': 'assets/midi/intermediate/seasons.mid',
      'Yesterday': 'assets/midi/intermediate/yesterday.mid',
      'Stand By Me': 'assets/midi/intermediate/stand_by_me.mid',
    },
    'Pro': {
      'Moonlight Sonata (1st mov.)': 'assets/midi/pro/moonlight.mid',
      'Let It Be (Beatles)': 'assets/midi/pro/let_it_be.mid',
      'Imagine (John Lennon)': 'assets/midi/pro/imagine.mid',
      'River Flows in You': 'assets/midi/pro/river_flows.mid',
      'Chopin Etude': 'assets/midi/pro/chopin_etude.mid',
      'Bach Fugue': 'assets/midi/pro/bach_fugue.mid',
      'Clocks': 'assets/midi/pro/clocks.mid',
      'Someone Like You': 'assets/midi/pro/someone_like_you.mid',
      'Bohemina Rhapsody (Intro)': 'assets/midi/pro/bohemina.mid',
      'Canon in D (full)': 'assets/midi/pro/canon_full.mid'
    },
  };

  Future<void> initialize() async {
    _libraryBox = await Hive.openBox<Recording>(_boxName);


  }

  // Get all library pieces by difficulty
  Map<String, List<String>> getLibraryPieces() {
    return {
      'Easy': libraryPieces['Easy']!.keys.toList(),
      'Intermediate': libraryPieces['Intermediate']!.keys.toList(),
      'Pro': libraryPieces['Pro']!.keys.toList(),
    };
  }

  // Load a piece from assets and convert to Recording
  Future<Recording?> loadLibraryPiece(String title) async {
    // Check if already cached in Hive
    final cached = _libraryBox.get(title);
    if (cached != null) return cached;

    // Find the asset path
    String? assetPath;
    for (var difficulty in libraryPieces.values) {
      if (difficulty.containsKey(title)) {
        assetPath = difficulty[title];
        break;
      }
    }

    if (assetPath == null) return null;

    try {
      // Load MIDI file from assets
      final byteData = await rootBundle.load(assetPath);
      final bytes = byteData.buffer.asUint8List();

      // Parse MIDI file to Recording
      final recording = await _parseMidiToRecording(bytes, title);

      // Cache in Hive
      await _libraryBox.put(title, recording);

      return recording;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading library piece $title: $e');
      }
      return null;
    }
  }

  // Import user MIDI file from device storage
  Future<Recording?> importMidiFile(File file, String title) async {
    try {
      final bytes = await file.readAsBytes();
      final recording = await _parseMidiToRecording(bytes, title);

      // Make sure imported files get the correct ID prefix
      final importedRecording = recording.copyWith(
        id: 'personal_${title}_${DateTime.now().millisecondsSinceEpoch}',
      );

      // Save to Hive
      await _libraryBox.put(importedRecording.id, importedRecording);

      return importedRecording;
    } catch (e) {
      if (kDebugMode) {
        print('Error importing MIDI file: $e');
      }
      return null;
    }
  }


  // Get all personal (imported + recorded) pieces
  List<Recording> getPersonalPieces() {
    return _libraryBox.values
        .where((r) => r.id.startsWith('personal_') || r.id.startsWith('recording_'))
        .toList();
  }

  // Parse MIDI file to Recording using our custom parser
  Future<Recording> _parseMidiToRecording(List<int> midiBytes, String title) async {
    return await MidiParser.parseToRecording(
      Uint8List.fromList(midiBytes),
      title,
    );
  }

  // Delete a piece
  Future<void> deletePiece(String id) async {
    await _libraryBox.delete(id);
  }


  void dispose() {
    _libraryBox.close();
  }
}