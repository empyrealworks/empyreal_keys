import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:empyrealkeys/models/recording.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class PianoState with ChangeNotifier {
  late StreamSubscription<List<ConnectivityResult>> _connSub;
  late Box _prefsBox;

  PianoState() {
    _prefsBox = Hive.box('pianoPrefs');
    _initialize();

    _connSub = Connectivity().onConnectivityChanged.listen((status) {
      if (status.contains(ConnectivityResult.none)) {
        resetInstrument(); // auto‑reset when you go offline
      }
    });
  }

  @override
  void dispose() {
    _connSub.cancel();
    super.dispose();
  }

  void _initialize() async {
    await _loadFromHive();

    // ✅ On every app launch, reset _showingScore
    _showingScore = false;

    notifyListeners();
  }

  Future<void> _loadFromHive() async {
    _panelHeight = _prefsBox.get('panelHeight', defaultValue: null);
    _currentNote = _prefsBox.get('currentNote', defaultValue: '..');
    _volume = _prefsBox.get('volume', defaultValue: 75);
    _octave = _prefsBox.get('octave', defaultValue: 3);
    _numberOfWhiteKeys = _prefsBox.get('numberOfWhiteKeys', defaultValue: 15);
    _selectedInstrument = _prefsBox.get('selectedInstrument', defaultValue: 'Default.SF2');
    _selectedInstrumentType = _prefsBox.get('selectedInstrumentType', defaultValue: 'Stein Grand');
    _chordType = _prefsBox.get('chordType', defaultValue: 'Major');
    _showNoteNames = _prefsBox.get('showNoteNames', defaultValue: false);
    _isChordMode = _prefsBox.get('isChordMode', defaultValue: false);
    _whiteKeyIndices = _prefsBox.get('whiteKeyIndices', defaultValue: [0, 2, 4, 5, 7, 9, 11, 12, 14, 16, 17, 19, 21, 23, 24]);
    _blackKeyIndices = _prefsBox.get('blackKeyIndices', defaultValue: [1, 3, 6, 8, 10, 13, 15, 18, 20, 22, 25]);
    // Metronome prefs
    _bpm = _prefsBox.get('bpm', defaultValue: 100);
    _metronomeSound = _prefsBox.get('metronomeSound', defaultValue: 'Click');
    _accentFirst = _prefsBox.get('accentFirst', defaultValue: false);
    _timeSig = _prefsBox.get('timeSig', defaultValue: '4/4');
    // PlayAlong prefs
    _loopEnabled = _prefsBox.get('loopEnabled', defaultValue: false);

    notifyListeners();
  }

  // PlayAlong State
  bool _loopEnabled = false;
  bool _showingScore = false;
  double? _panelHeight;
  String? _selectedPiece;
  Set<int> _activePlayAlongNotes = {};
  Set<int> _pressedNotes = {};


  // Recorder State
  final List<Recording> _recordings = [];

  //Metronome State
  int _bpm = 100;
  String _timeSig = "4/4";
  String _metronomeSound = 'Click'; // or "Piano", "Woodblock"
  bool _accentFirst = false;
  bool _isPlayingMetronome = false;

  //Piano State
  final Map<String, List<Map<String, String>>> _instruments = {
    'Piano': [
      {'Electric Grand': '198_u20_Electric_Grand.sf2'},
      {'Yamaha SY1': '198_Yamaha_SY1_piano.sf2'},
      {'Stein Grand': 'Default.SF2'},
      {'Rock Organ': 'Rock Organ.sf2'},
      {'Jazz Organ': '1_M3R_Jazz_Organ.SF2'},
      {'Organ': '361_Organ_B3.SF2'},
    ],
    'Strings': [
      {'Violin': 'ensemble violin.sf2'},
      {'Cello': 'Concerto Cello.SF2'},
      {'Viola': 'ViolasLong.sf2'},
      {'Guitar (Acoustic)': 'Guitar Acoustic (963KB).sf2'},
      {'Guitar (Electric)': 'Ibanez Electric Guitar.SF2'},
      {'Bass': '241-Bassguitars.SF2'},
    ],
    'Brass': [
      {'Trumpet': 'Joshua_Melodic_Trumpet.SF2'},
      {'Trombone': 'JL_Trombone_New.sf2'},
      {'Saxophone': '198_u20_alto_sax.SF2'},
    ],
    'Woodwind': [
      {'Flute': 'CamsFlute.SF2'},
      {'Clarinet': 'SJO - Clarinet.sf2'},
      {'Oboe': '142_Oboe_Stereo.sf2'},
    ],
    'Percussion': [
      {'Drums': 'HS African Percussion.sf2'}
    ],
    'Voice': [
      {'Choir': 'KBH-Real-Choir-V2.5.sf2'},
      {'Boy Choir': 'Boychoir.sf2'},
      {'Opera Female': 'OperaSingerFemale3.sf2'},
      {'Heaven': 'VoiceOfHeaven.sf2'},
    ],
  };
  final List<String> _notes = [
    'C',
    'C#',
    'D',
    'D#',
    'E',
    'F',
    'F#',
    'G',
    'G#',
    'A',
    'A#',
    'B',
    'C',
    'C#',
    'D',
    'D#',
    'E',
    'F',
    'F#',
    'G',
    'G#',
    'A',
    'A#',
    'B',
    "C"
  ];
  final Map<String, List<int>> _chordFormulas = {
    'Major': [0, 4, 7, 12],
    'Minor': [0, 3, 7],
    'Diminished': [0, 3, 6],
    'Augmented': [0, 4, 8],
    'Major 7': [0, 4, 7, 11],
    'Minor 7': [0, 3, 7, 10],
    'Dominant 7': [0, 4, 7, 10],
    'Sus2': [0, 2, 7],
    'Sus4': [0, 5, 7],
  };
  String _chordType = 'Major';
  String _currentNote = '..';
  int _volume = 75;
  int _octave = 3;
  int _numberOfWhiteKeys = 15;
  String _selectedInstrument = 'Default.SF2';
  String _selectedInstrumentType = 'Stein Grand';
  bool _showNoteNames = false;
  bool _isChordMode = false;
  List<int> _whiteKeyIndices = [
    0, 2, 4, 5, 7, 9, 11, 12, 14, 16, 17, 19, 21, 23, 24,
  ];
  List<int> _blackKeyIndices = [1, 3, 6, 8, 10, 13, 15, 18, 20, 22, 25];
  List<double> _blackKeyOffsets = [
    0.75,
    1.75,
    3.75,
    4.75,
    5.75,
    7.75,
    8.75,
    10.75,
    11.75,
    12.75,
    14.75
  ];

  Map<String, List<int>> get chordFormulas => _chordFormulas;
  List<double> get blackKeyOffsets => _blackKeyOffsets;
  List<int> get whiteKeyIndices => _whiteKeyIndices;
  List<int> get blackKeyIndices => _blackKeyIndices;
  Map<String, List<Map<String, String>>> get instruments => _instruments;
  List<String> get notes => _notes;
  String get currentNote => _currentNote;
  int get volume => _volume;
  int get octave => _octave;
  int get numberOfKeys => _numberOfWhiteKeys;
  String get selectedInstrument => _selectedInstrument;
  String get selectedInstrumentType => _selectedInstrumentType;
  String get chordType => _chordType;
  bool get isChordMode => _isChordMode;
  bool get showNoteNames => _showNoteNames;
  //Metronome Getters
  int get bpm => _bpm;
  String get timeSig => _timeSig;
  String get metronomeSound => _metronomeSound;
  bool get accentFirst => _accentFirst;
  bool get isPlayingMetronome => _isPlayingMetronome;
  //Recorder Getters
  List<Recording> get recordings => List.unmodifiable(_recordings);
  //Playalong Getters
  bool get loopEnabled => _loopEnabled;
  double? get panelHeight => _panelHeight;
  String? get selectedPiece => _selectedPiece;
  bool get showingScore => _showingScore;
  Set<int> get activePlayAlongNotes => _activePlayAlongNotes;
  Set<int> get pressedNotes => _pressedNotes;


  void showScore(String piece, double screenHeight) {
    _selectedPiece = piece;
    _showingScore = true;
    notifyListeners();
  }

  void hideScore(double screenHeight) {
    _selectedPiece = null;
    _showingScore = false;
    notifyListeners();
  }

  // playalong Setters
  void setLoopEnabled(bool val) {
    _loopEnabled = val;
    _prefsBox.put('loopEnabled', val);
    notifyListeners();
  }

  void setActivePlayAlongNotes(Set<int> notes) {
    _activePlayAlongNotes = notes;
    notifyListeners();
  }

  void addActivePlayAlongNote(int note) {
    _activePlayAlongNotes.add(note);
    notifyListeners();
  }

  void removeActivePlayAlongNote(int note) {
    _activePlayAlongNotes.remove(note);
    notifyListeners();
  }

  void clearActivePlayAlongNotes() {
    _activePlayAlongNotes.clear();
    notifyListeners();
  }

  void setPressedNotes(Set<int> notes) {
    _pressedNotes = notes;
    notifyListeners();
  }

  void addPressedNote(int note) {
    if (_pressedNotes.add(note)) {
      notifyListeners();
    }
  }

  void removePressedNote(int note) {
    if (_pressedNotes.remove(note)) {
      notifyListeners();
    }
  }

  //Metronome Setters
  void setBpm(int newBpm) {
    _bpm = newBpm.clamp(30, 300); // safety clamp
    _prefsBox.put('bpm', _bpm);
    notifyListeners();
  }

  void setAccentFirst(bool val) {
    _accentFirst = val;
    _prefsBox.put('accentFirst', val);
    notifyListeners();
  }

  void setMetronomeSound(String sound) {
    _metronomeSound = sound;
    _prefsBox.put('metronomeSound', sound);
    notifyListeners();
  }

  void setTimeSignature(String sig) {
    _timeSig = sig;
    _prefsBox.put('timeSig', sig);
    notifyListeners();
  }

  void setPlaying(bool val) {
    _isPlayingMetronome = val;
    notifyListeners();
  }

  // Piano Setters
  void setChordType(String type) {
    _chordType = type;
    _prefsBox.put('chordType', type);
    notifyListeners();
  }

  void setIsChordMode(bool enabled) {
    _isChordMode = enabled;
    _prefsBox.put('isChordMode', enabled);
    notifyListeners();
  }

  void setWhiteKeyIndices(List<int> indices) {
    _whiteKeyIndices = indices;
    _prefsBox.put('whiteKeyIndices', indices);
    notifyListeners();
  }
  void setBlackKeyIndices(int numberOfKeys) {
    _blackKeyIndices = _generateBlackKeyIndices(numberOfKeys);
    _prefsBox.put('blackKeyIndices', _blackKeyIndices);
    notifyListeners();
  }

  void setShowNoteNames(bool show) {
    _showNoteNames = show;
    _prefsBox.put('showNoteNames', show);
    notifyListeners();
  }

  void setCurrentNote(String note) {
    _currentNote = note;
    _prefsBox.put('currentNote', note);
    notifyListeners(); // notifies all listeners to rebuild
  }

  void setVolume(int volume) {
    _volume = volume;
    _prefsBox.put('volume', volume);
    notifyListeners();
  }

  void setOctave(int octave) {
    _octave = octave;
    _prefsBox.put('octave', octave);
    notifyListeners();
  }

  void setNumberOfWhiteKeys(int numberOfKeys) {
    _numberOfWhiteKeys = numberOfKeys;
    _generateKeyIndices();
    _prefsBox.put('numberOfWhiteKeys', numberOfKeys);
    notifyListeners();
  }

  void setInstrument(String newInstrument) {
    _selectedInstrument = newInstrument;
    _prefsBox.put('selectedInstrument', newInstrument);
    notifyListeners();
  }

  void setInstrumentType(String newInstrumentType) {
    _selectedInstrumentType = newInstrumentType;
    _prefsBox.put('selectedInstrumentType', newInstrumentType);
    notifyListeners();
  }

  void _generateKeyIndices() {
    _whiteKeyIndices = _generateWhiteKeyIndices(_numberOfWhiteKeys);
    _blackKeyIndices = _generateBlackKeyIndices(_numberOfWhiteKeys);
  }

  List<int> _generateWhiteKeyIndices(int count) {
    List<int> pattern = [0, 2, 4, 5, 7, 9, 11];
    List<int> indices = [];
    int octave = 0;

    while (indices.length < count) {
      for (int val in pattern) {
        indices.add(val + (12 * octave));
        if (indices.length == count) break;
      }
      octave++;
    }

    return indices;
  }

  List<int> _generateBlackKeyIndices(int whiteCount) {
    List<int> pattern = [1, 3, 6, 8, 10];
    List<int> indices = [];
    int octaves = (whiteCount / 7).ceil();

    for (int i = 0; i < octaves; i++) {
      for (int val in pattern) {
        indices.add(val + (12 * i));
      }
    }
    // if(whiteCount == 15) indices.add(25);
    return indices;
  }

  List<double> generateBlackKeyOffsets(int whiteKeyCount) {
    List<double> pattern = [0.75, 1.75, 3.75, 4.75, 5.75];
    List<double> offsets = [];

    int fullOctaves = whiteKeyCount ~/ 7;
    int remainingWhiteKeys = whiteKeyCount % 7;

    for (int octave = 0; octave < fullOctaves; octave++) {
      double base = 7.0 * octave;
      for (double val in pattern) {
        offsets.add(base + val);
      }
    }
    // if(whiteKeyCount == 15) offsets.add(7.0 * octave + 0.75);

    // Add black key offsets for remaining partial octave
    List<double> partialPattern = [];
    switch (remainingWhiteKeys) {
      case 6:
        partialPattern = [0.75, 1.75, 3.75, 4.75, 5.75];
        break;
      case 5:
        partialPattern = [0.75, 1.75, 3.75, 4.75];
        break;
      case 4:
        partialPattern = [0.75, 1.75, 3.75];
        break;
      case 3:
        partialPattern = [0.75, 1.75];
        break;
      case 2:
        partialPattern = [0.75];
        break;
      case 1:
      case 0:
      default:
        partialPattern = [];
    }

    double lastBase = 7.0 * fullOctaves;
    offsets.addAll(partialPattern.map((e) => lastBase + e));

    return offsets;
  }
  void setBlackKeyOffsets(List<double> offsets) {
    _blackKeyOffsets = offsets;
    notifyListeners();
  }

  // Reset settings to default
  void resetToDefault(){
    _currentNote = '..';
    _volume = 75;
    _octave = 4;
    _numberOfWhiteKeys = 14;
    _selectedInstrument = 'Default.SF2';
    _selectedInstrumentType = 'Stein Grand';
    _showNoteNames = false;
    _isChordMode = false;
    _chordType = 'Major';
    _whiteKeyIndices = [0, 2, 4, 5, 7, 9, 11, 12, 14, 16, 17, 19, 21, 23, 24];
    _blackKeyIndices = [1, 3, 6, 8, 10, 13, 15, 18, 20, 22, 25];
    // Metronome defaults
    _bpm = 100;
    _metronomeSound = 'Click';
    _accentFirst = false;
    _timeSig = '4/4';

    notifyListeners();
  }

  /// Reset only the instrument back to the built‑in default.
  void resetInstrument() {
    _selectedInstrument      = 'Default.SF2';
    _selectedInstrumentType  = 'Stein Grand';
    // persist
    _prefsBox.put('selectedInstrument',     _selectedInstrument);
    _prefsBox.put('selectedInstrumentType', _selectedInstrumentType);
    notifyListeners();
  }
}
