// piano_keys.dart
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:empyrealkeys/components/piano_keyboard/white_keys.dart';
import 'package:provider/provider.dart';

import '../../state/midi_provider.dart';
import '../../state/piano_state.dart';
import 'black_keys.dart';
import 'piano_key_listener.dart'; // Import the new widget

class PianoKeys extends StatefulWidget {
  const PianoKeys({super.key});

  @override
  State<PianoKeys> createState() => _PianoKeysState();
}

class _PianoKeysState extends State<PianoKeys> {
  var _displayedNote = '...';

  void onKeyPress(String note) {
    setState(() {
      _displayedNote = note;
    });
  }

  @override
  Widget build(BuildContext context) {
    final showNoteName =
        Provider.of<PianoState>(context, listen: false).showNoteNames;
    final numberOfKeys = Provider.of<PianoState>(context).numberOfKeys;
    final whiteKeyIndices = Provider.of<PianoState>(context).whiteKeyIndices;
    final blackKeyIndices = Provider.of<PianoState>(context).blackKeyIndices;
    final blackKeyOffsets = Provider.of<PianoState>(context).blackKeyOffsets;
    final notes = Provider.of<PianoState>(context).notes;
    final screenWidth = MediaQuery.sizeOf(context).width;

    List<Widget> blackKeys = [];

    double whiteKeyWidth = (screenWidth - 60) /
        numberOfKeys; // 60 is total padding around row of piano keys
    double blackKeyWidth = whiteKeyWidth * 0.5;
    int minLength = math.min(blackKeyIndices.length, blackKeyOffsets.length);
    for (int i = 0; i < minLength; i++) {
      blackKeys.add(Positioned(
        left: whiteKeyWidth * blackKeyOffsets[i],
        child: BlackKey(
          idx: blackKeyIndices[i],
          keyWidth: blackKeyWidth,
        ),
      ));
    }

    List<Widget> whiteKeyLabels = [];
    // generate white key labels widget list
    for (int i = 0; i < whiteKeyIndices.length; i++) {
      whiteKeyLabels.add(
        Positioned(
            left: whiteKeyWidth * i + whiteKeyWidth / 2 - 5,
            bottom: 10,
            child: Text(
              notes[whiteKeyIndices[i]],
              style: TextStyle(
                  color: showNoteName ? Colors.black45 : Colors.transparent,
                  fontWeight: FontWeight.bold),
            )),
      );
    }

    return Expanded(
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF000000),
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(15),
              topRight: Radius.circular(15),
              bottomRight: Radius.circular(30),
              bottomLeft: Radius.circular(30)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child:
              Consumer<MidiProvider>(builder: (context, midiProvider, child) {
            return midiProvider.isSoundfontLoaded
                ? PianoKeyListener(
                    whiteKeyIndices: whiteKeyIndices,
                    blackKeyIndices: blackKeyIndices,
                    blackKeyOffsets: blackKeyOffsets,
                    whiteKeyWidth: whiteKeyWidth,
                    blackKeyWidth: blackKeyWidth,
                    numberOfKeys: numberOfKeys,
                    child: Stack(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(numberOfKeys, (index) {
                            String keyType;

                            // Assign the key type based on the index
                            if (index == 0) {
                              keyType = 'leftKey';
                            } else if (index == numberOfKeys - 1) {
                              keyType = 'rightKey';
                            } else {
                              keyType = 'centralKey';
                            }
                            return Expanded(
                                child: WhiteKey(
                              idx: whiteKeyIndices[index],
                              keyType: keyType,
                              showNoteName: showNoteName,
                            ));
                          }),
                        ),
                        ...blackKeys,
                        ...whiteKeyLabels
                      ],
                    ),
                  )
                : Stack(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(numberOfKeys, (index) {
                          String keyType;

                          // Assign the key type based on the index
                          if (index == 0) {
                            keyType = 'leftKey';
                          } else if (index == numberOfKeys - 1) {
                            keyType = 'rightKey';
                          } else {
                            keyType = 'centralKey';
                          }
                          return Expanded(
                              child: WhiteKey(
                            idx: whiteKeyIndices[index],
                            keyType: keyType,
                            showNoteName: showNoteName,
                          ));
                        }),
                      ),
                      ...blackKeys,
                      Container(
                          color: Colors.black.withValues(alpha: 0.7),
                          child:
                              const Center(child: CircularProgressIndicator())),
                    ],
                  );
          }),
        ),
      ),
    );
  }
}
