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
    final pianoState = Provider.of<PianoState>(context);
    final octave = pianoState.octave;
    final midiNote = 12 + (octave * 12) + idx;
    final isHighlighted = pianoState.activePlayAlongNotes.contains(midiNote);
    final isPressed = pianoState.pressedNotes.contains(midiNote);

    // same height logic you had before
    final double keyHeight = pianoState.showingScore
        ? pianoState.panelHeight! * 0.35
        : MediaQuery.of(context).size.height * 0.33;

    return SizedBox(
      width: keyWidth,
      height: keyHeight,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // main black key body
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
                colors: isHighlighted
                    ? const [Color(0xFF01353A), Color(0xFF054B50)]
                    : const [Color(0xFF0B0B0B), Color(0xFF222222)],
                stops: const [0.0, 1.0],
              ),
              boxShadow: [
                // drop shadow to suggest height
                BoxShadow(
                  color: Colors.black.withOpacity(0.55),
                  offset: const Offset(3, 6),
                  blurRadius: 10,
                ),
                // subtle rim highlight on left/top edge
                BoxShadow(
                  color: Colors.white.withOpacity(0.03),
                  offset: const Offset(-1, -1),
                  blurRadius: 2,
                ),
                // subtle rim highlight on bottom/right edge
                BoxShadow(
                  color: Colors.white.withOpacity(0.03),
                  offset: const Offset(-1, 1),
                  blurRadius: 2,
                ),
              ],
              border: isPressed
                  ? Border.all(color: Colors.white.withOpacity(0.12), width: 1.2)
                  : null,
            ),
          ),

          // specular top highlight (thin glossy streak)
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
                      Colors.white.withOpacity(0.12),
                      Colors.white.withOpacity(0.06),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.35, 1.0],
                  ),
                ),
              ),
            ),
          ),
          // specular bottom highlight (thin glossy streak)
          Positioned(
            left: 6,
            right: 6,
            bottom: 10,
            height: keyHeight * 0.18,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: LinearGradient(
                    end: Alignment.topCenter,
                    begin: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(isPressed ? 0.20 : 0.12),
                      Colors.white.withOpacity(0.06),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.35, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // thin lateral highlight for glossy bevel
          Positioned(
            left: 6,
            top: 6,
            bottom: 15,
            width: 2,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.06),
                      Colors.white.withOpacity(0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          // thin lateral highlight for glossy bevel
          Positioned(
            left: 6,
            top: 6,
            bottom: 15,
            width: 2,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    end: Alignment.topLeft,
                    begin: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          // thin lateral highlight for glossy bevel
          Positioned(
            right: 6,
            top: 6,
            bottom: 15,
            width: 2,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    end: Alignment.topLeft,
                    begin: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // pressed/highlight overlay (subtle)
          if (isPressed)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.02),
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
