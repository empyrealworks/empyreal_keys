import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/piano_state.dart';

class BlackKey extends StatelessWidget {
  final double keyWidth;
  final int idx;
  const BlackKey({
    super.key,
    required this.keyWidth,
    required this.idx,
  });

  @override
  Widget build(BuildContext context) {
    final octave = context.select<PianoState, int>((s) => s.octave);
    final midiNote = 12 + (octave * 12) + idx;
    
    final isPressed = context.select<PianoState, bool>(
      (s) => s.pressedNotes.contains(midiNote)
    );
    final isPlayAlong = context.select<PianoState, bool>(
      (s) => s.activePlayAlongNotes.contains(midiNote)
    );
    
    final showingScore = context.select<PianoState, bool>((s) => s.showingScore);
    final screenHeight = MediaQuery.of(context).size.height;

    final double keyHeight = showingScore
        ? screenHeight * 0.194
        : screenHeight * 0.33;

    return SizedBox(
      width: keyWidth,
      height: keyHeight,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isPlayAlong
                    ? const [Color(0xFF01353A), Color(0xFF054B50)]
                    : isPressed
                        ? const [Color(0xFF333333), Color(0xFF555555)]
                        : const [Color(0xFF0B0B0B), Color(0xFF222222)],
                stops: const [0.0, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.55),
                  offset: const Offset(3, 6),
                  blurRadius: 10,
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.03),
                  offset: const Offset(-1, -1),
                  blurRadius: 2,
                ),
              ],
              border: isPressed
                  ? Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.2)
                  : null,
            ),
          ),

          // specular top highlight
          Positioned(
            left: 4,
            right: 4,
            top: 0,
            height: keyHeight * 0.18,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.12),
                      Colors.white.withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.35, 1.0],
                  ),
                ),
              ),
            ),
          ),
          
          // pressed/highlight overlay
          if (isPressed)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(6),
                      bottomRight: Radius.circular(6),
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
