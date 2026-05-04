import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/piano_state.dart';


class Display extends StatelessWidget {
  const Display({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PianoState>(builder: (context, pianoState, child) {
      return Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0XFF282424),
                Color(0xFF282424)
              ],
              stops: [
                0,1
              ]
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.7),  // Dark shadow
              offset: const Offset(-4, -4),  // Bottom-right shadow
              blurRadius: 10,  // Soften the shadow
              spreadRadius: -4,  // Make the shadow tighter inside
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.2),  // Highlight shadow
              offset: const Offset(-4, -4),  // Top-left shadow for highlighting
              blurRadius: 10,
              spreadRadius: -4,  // Spread towards the inside
            ),
          ],
          borderRadius: BorderRadius.circular(15),
          color: const Color(0xFF282424),

        ),
        margin: EdgeInsets.symmetric(horizontal: MediaQuery.sizeOf(context).width * 0.02),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width / 2.5,
        ),
        height: MediaQuery.sizeOf(context).width * 0.09,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(pianoState.octave.toString(), style: TextStyle(fontSize: MediaQuery.sizeOf(context).width * 0.03, color: Colors.grey, fontFamily: 'AtomicClockRadio'),),
                Text('8va', style: TextStyle(fontSize: MediaQuery.sizeOf(context).width * 0.01, color: Colors.grey, fontFamily: 'AtomicClockRadio'),),
              ],
            ),
            Text(pianoState.currentNote, style: TextStyle(fontSize: MediaQuery.sizeOf(context).width * 0.05, color: Colors.grey, fontFamily: 'AtomicClockRadio'),),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${pianoState.volume.toInt()}', style: TextStyle(fontSize: MediaQuery.sizeOf(context).width * 0.03, color: Colors.grey, fontFamily: 'AtomicClockRadio'),),
                Text('vol', style: TextStyle(fontSize: MediaQuery.sizeOf(context).width * 0.01, color: Colors.grey, fontFamily: 'AtomicClockRadio'),),
              ],
            ),
          ],
        ),
      );
    });
  }
}
