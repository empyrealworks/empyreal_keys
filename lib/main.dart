// main.dart - Updated initialization
import 'package:empyrealkeys/models/note_event.dart';
import 'package:empyrealkeys/models/recording.dart';
import 'package:empyrealkeys/services/play_along_service.dart';
import 'package:empyrealkeys/services/library_service.dart';
import 'package:empyrealkeys/state/recorder_service.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:empyrealkeys/screens/piano_screen.dart';
import 'package:empyrealkeys/services/soundfont.dart';
import 'package:empyrealkeys/state/midi_provider.dart';
import 'package:empyrealkeys/state/piano_state.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'components/app_theme.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  final appDocDir = await getApplicationDocumentsDirectory();
  Hive.init(appDocDir.path);

  // Register Hive Adapters (IMPORTANT!)
  Hive.registerAdapter(NoteEventAdapter());
  Hive.registerAdapter(RecordingAdapter());

  // Open boxes
  await Hive.openBox('pianoPrefs');
  await Hive.openBox('recorderPrefs');

  // Initialize library service
  final libraryService = LibraryService();
  await libraryService.initialize();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    if (kDebugMode) {
      print('Failed to initialize Firebase: $e');
    }
  }

  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity,
      appleProvider: AppleProvider.debug,
    );
  } catch (e) {
    if (kDebugMode) {
      print("Failed to activate Firebase App Check: $e");
    }
  }

  final soundfontService = SoundfontService();

  runApp(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (BuildContext context) => PianoState()),
        ChangeNotifierProvider(create: (context) {
          final pianoState = Provider.of<PianoState>(context, listen: false);
          return MidiProvider(
              font: pianoState.selectedInstrument,
              soundfontService: soundfontService
          );
        }),
        ChangeNotifierProvider(create: (context) => RecorderService()),
        ChangeNotifierProvider(create: (context) => PlayAlongService()),
        Provider.value(value: libraryService),
      ],
      child: const PianoApp()
  ));
}

class PianoApp extends StatelessWidget {
  const PianoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Piano',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const PianoScreen(),
      routes: {
        PianoScreen.name: (context) => const PianoScreen(),
      },
    );
  }
}
