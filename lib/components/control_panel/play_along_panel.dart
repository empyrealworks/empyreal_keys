import 'package:empyrealkeys/components/control_panel/personal_bottom_sheet.dart';
import 'package:empyrealkeys/components/control_panel/scrolling_score_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/play_along_service.dart';
import '../../state/midi_provider.dart';
import '../../state/piano_state.dart';
import 'library_bottom_sheet.dart';

class PlayAlongPanel extends StatefulWidget {
  final double screenWidth;
  final double screenHeight;
  const PlayAlongPanel({
    super.key,
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  State<PlayAlongPanel> createState() => _PlayAlongPanelState();
}

class _PlayAlongPanelState extends State<PlayAlongPanel> {
  @override
  Widget build(BuildContext context) {
    final pianoState = Provider.of<PianoState>(context);
    final playAlongService = Provider.of<PlayAlongService>(context);
    final midiProvider = Provider.of<MidiProvider>(context, listen: false);

    // Score viewing mode
    if (pianoState.showingScore && playAlongService.currentPiece != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Title and controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "Now Playing: ${playAlongService.currentPiece!.title}",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: widget.screenHeight * 0.025,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Play/Pause button
              IconButton(
                icon: Icon(
                  playAlongService.isPlaying && !playAlongService.isPaused
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: widget.screenHeight * 0.06,
                ),
                onPressed: () {
                  if (!playAlongService.isPlaying) {
                    playAlongService.startPlayback(
                      onNoteOn: (event) {
                        midiProvider.playNote(
                          midiNote: event.midiNote,
                          velocity: event.velocity,
                        );
                      },
                      onNoteOff: (event) {
                        midiProvider.stopNote(midiNote: event.midiNote);
                      },
                      onActiveNotesChanged: (notes) {
                        pianoState.setActivePlayAlongNotes(notes);
                      },
                    );
                  } else {
                    if (playAlongService.isPaused) {
                      playAlongService.resumePlayback();
                    } else {
                      playAlongService.pausePlayback();
                      // Stop all active MIDI notes before pausing
                      for (int note = 0; note < 128; note++) {
                        midiProvider.stopNote(midiNote: note);
                      }
                      playAlongService.pausePlayback();
                      pianoState.clearActivePlayAlongNotes();
                    }
                  }
                },
              ),
              // Stop button
              IconButton(
                icon: Icon(
                  Icons.stop_rounded,
                  color: Colors.white,
                  size: widget.screenHeight * 0.06,
                ),
                onPressed: () {
                  // Stop all active MIDI notes first
                  for (int note = 0; note < 128; note++) {
                    midiProvider.stopNote(midiNote: note);
                  }
                  playAlongService.stopPlayback();
                  pianoState.clearActivePlayAlongNotes();
                },
              ),
            ],
          ),

          // Progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Row(
              children: [
                Text(
                  _formatDuration(playAlongService.playbackPosition),
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18.0),
                    child: SliderTheme(
                      data: SliderThemeData(
                        thumbShape:
                            RoundSliderThumbShape(enabledThumbRadius: 8),
                        trackHeight: 3,
                      ),
                      child: Slider(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        value: playAlongService.playbackPosition.clamp(
                            0.0,
                            playAlongService.totalDuration.isFinite
                                ? playAlongService.totalDuration
                                : 1.0),
                        min: 0,
                        max: playAlongService.totalDuration.isFinite
                            ? playAlongService.totalDuration
                            : 1.0,
                        activeColor: Theme.of(context).primaryColor,
                        inactiveColor: Colors.grey,
                        onChanged: (value) {
                          playAlongService.seekTo(value);
                        },
                      ),
                    ),
                  ),
                ),
                Text(
                  _formatDuration(playAlongService.totalDuration),
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),

          // Scrolling Score Widget
          Expanded(
            child: ScrollingScoreWidget(
              recording: playAlongService.currentPiece!,
              currentPosition: playAlongService.playbackPosition,
              screenHeight: widget.screenHeight,
            ),
          ),
        ],
      );
    }

    // Control Panel Mode
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // PlayAlong indicator
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Icon(
                      Icons.queue_music_rounded,
                      color: Theme.of(context).primaryColor,
                      size: widget.screenWidth * 0.025,
                    ),
                  ),

                  // Library button
                  IconButton(
                    iconSize: widget.screenHeight * 0.1,
                    icon: const Icon(
                      Icons.library_music_rounded,
                      color: Color(0xFFBCBCBC),
                    ),
                    onPressed: () async {
                      final result = await showModalBottomSheet<String>(
                        context: context,
                        backgroundColor: const Color(0xFF2C2C2E),
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(30)),
                        ),
                        isScrollControlled: true,
                        builder: (context) => const LibraryBottomSheet(),
                      );
                      if (result != null) {
                        pianoState.showScore(result, widget.screenHeight);
                      }
                    },
                  ),
                  SizedBox(width: widget.screenWidth * 0.01),

                  // Personal library button
                  IconButton(
                    iconSize: widget.screenHeight * 0.1,
                    icon: const Icon(
                      Icons.folder_special_rounded,
                      color: Color(0xFFBCBCBC),
                    ),
                    onPressed: () async {
                      final result = await showModalBottomSheet<String>(
                        context: context,
                        backgroundColor: const Color(0xFF2C2C2E),
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(30)),
                        ),
                        isScrollControlled: true,
                        builder: (context) => const PersonalBottomSheet(),
                      );
                      if (result != null) {
                        pianoState.showScore(result, widget.screenHeight);
                      }
                    },
                  ),

                  // Tempo controls
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: GestureDetector(
                          onTap: () {
                            final newTempo =
                                (playAlongService.tempoMultiplier - 0.05)
                                    .clamp(0.5, 1.5);
                            playAlongService.setTempoMultiplier(newTempo);
                          },
                          child: Icon(
                            Icons.remove_rounded,
                            color: const Color(0xFFBCBCBC),
                            size: widget.screenWidth * 0.04,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () async {
                          final controller = TextEditingController(
                            text:
                                '${(playAlongService.tempoMultiplier * 100).toInt()}',
                          );
                          final newVal = await showDialog<int>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: const Color(0xFF2C2C2E),
                              title: const Text(
                                "Set Tempo %",
                                style: TextStyle(color: Colors.white),
                              ),
                              content: TextField(
                                controller: controller,
                                keyboardType: TextInputType.number,
                                style: TextStyle(
                                  fontSize: widget.screenHeight * 0.05,
                                  color: Colors.white,
                                ),
                                decoration: const InputDecoration(
                                  hintText: "50-150",
                                  hintStyle: TextStyle(color: Colors.grey),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("Cancel"),
                                ),
                                TextButton(
                                  onPressed: () {
                                    final parsed =
                                        int.tryParse(controller.text);
                                    Navigator.pop(context, parsed);
                                  },
                                  child: const Text("OK"),
                                ),
                              ],
                            ),
                          );
                          if (newVal != null) {
                            playAlongService.setTempoMultiplier(
                                (newVal / 100).clamp(0.5, 1.5));
                          }
                        },
                        child: Text(
                          '${(playAlongService.tempoMultiplier * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: widget.screenHeight * 0.07,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFBCBCBC),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: GestureDetector(
                          onTap: () {
                            final newTempo =
                                (playAlongService.tempoMultiplier + 0.05)
                                    .clamp(0.5, 1.5);
                            playAlongService.setTempoMultiplier(newTempo);
                          },
                          child: Icon(
                            Icons.add_rounded,
                            color: const Color(0xFFBCBCBC),
                            size: widget.screenWidth * 0.04,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Loop toggle
                  IconButton(
                    iconSize: widget.screenHeight * 0.1,
                    onPressed: () {
                      pianoState.setLoopEnabled(!pianoState.loopEnabled);
                      if (pianoState.loopEnabled &&
                          playAlongService.loopStart == null) {
                        // Set default loop region (first 30% to 70% of piece)
                        final duration = playAlongService.totalDuration;
                        playAlongService.setLoopRegion(
                          duration * 0.01,
                          duration * 0.99,
                        );
                      } else if (!pianoState.loopEnabled) {
                        playAlongService.clearLoopRegion();
                      }
                    },
                    icon: Icon(
                      Icons.loop_rounded,
                      color: pianoState.loopEnabled
                          ? Theme.of(context).primaryColor
                          : const Color(0xFFBCBCBC),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDuration(double seconds) {
    final duration = Duration(seconds: seconds.toInt());
    final minutes = duration.inMinutes;
    final secs = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
