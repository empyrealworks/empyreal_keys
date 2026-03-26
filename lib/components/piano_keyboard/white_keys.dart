import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/piano_state.dart';

class WhiteKey extends StatefulWidget {
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
  State<WhiteKey> createState() => _WhiteKeyState();
}

class _WhiteKeyState extends State<WhiteKey> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final pianoState = Provider.of<PianoState>(context);
    final octave = pianoState.octave;
    final midiNote = 12 + (octave * 12) + widget.idx;
    final isHighlighted = pianoState.activePlayAlongNotes.contains(midiNote);

    return GestureDetector(
      onPanStart: (details) {
        setState(() {
          _isPressed = false;
        });
      },
      onTapDown: (details) {
        setState(() {
          _isPressed = true;
        });
      },
      onTapUp: (details) {
        setState(() {
          _isPressed = false;
        });
      },
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: _isPressed
                    ? [
                  Colors.grey.withValues(alpha: 0.1),
                  Colors.grey.withValues(alpha: 0.05),
                ]
                    : isHighlighted
                    ? [
                  Colors.white,
                  Theme.of(context).primaryColor.withValues(alpha: 0.18),
                ]
                    : [Colors.white, Colors.grey.shade100],
              ),
              borderRadius: _getBorderRadius(widget.keyType),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  offset: const Offset(2, 3), // slight right-down shadow
                  blurRadius: 6,
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.6),
                  offset: const Offset(-1, -1), // subtle top-left highlight
                  blurRadius: 2,
                ),
              ],
            ),
            margin: const EdgeInsets.all(2),
          ),
        ],
      ),
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