import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/piano_state.dart';

class WhiteKey extends StatelessWidget {
  final String keyType;
  final int idx;
  final bool showNoteName;

  const WhiteKey({
    super.key,
    required this.keyType,
    required this.idx,
    required this.showNoteName,
  });

  @override
  Widget build(BuildContext context) {
    final octave = context.select<PianoState, int>((s) => s.octave);
    final midiNote = 12 + (octave * 12) + idx;
    
    // Listen to whether this specific note is pressed
    final isPressed = context.select<PianoState, bool>(
      (s) => s.pressedNotes.contains(midiNote)
    );
    
    // Listen to whether it's highlighted for play-along
    final isPlayAlong = context.select<PianoState, bool>(
      (s) => s.activePlayAlongNotes.contains(midiNote)
    );

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isPressed
                  ? [
                Colors.grey.withValues(alpha: 0.2),
                Colors.grey.withValues(alpha: 0.4),
              ]
                  : isPlayAlong
                  ? [
                Colors.white,
                Theme.of(context).primaryColor.withValues(alpha: 0.18),
              ]
                  : [Colors.white, Colors.grey.shade100],
            ),
            borderRadius: _getBorderRadius(keyType),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                offset: const Offset(2, 3),
                blurRadius: 6,
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.6),
                offset: const Offset(-1, -1),
                blurRadius: 2,
              ),
            ],
          ),
          margin: const EdgeInsets.all(2),
        ),
      ],
    );
  }

  BorderRadius _getBorderRadius(String keyType) {
    switch (keyType) {
      case 'rightKey':
        return const BorderRadius.only(
          topRight: Radius.circular(10),
          bottomRight: Radius.circular(20),
          bottomLeft: Radius.circular(5),
        );
      case 'leftKey':
        return const BorderRadius.only(
          topLeft: Radius.circular(10),
          bottomRight: Radius.circular(5),
          bottomLeft: Radius.circular(20),
        );
      default:
        return const BorderRadius.only(
          topLeft: Radius.circular(5),
          topRight: Radius.circular(5),
          bottomRight: Radius.circular(5),
          bottomLeft: Radius.circular(5),
        );
    }
  }
}
