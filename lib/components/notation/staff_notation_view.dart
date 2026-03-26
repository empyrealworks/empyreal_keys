// components/notation/staff_notation_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_music_notation/flutter_music_notation.dart' as fmn;
import '../../models/recording.dart';
import '../../services/notation_bridge.dart';

enum NotationScrollMode { horizontal, vertical }

class StaffNotationView extends StatefulWidget {
  final Recording recording;
  final double currentPosition;
  final double screenHeight;
  final NotationScrollMode scrollMode;

  const StaffNotationView({
    super.key,
    required this.recording,
    required this.currentPosition,
    required this.screenHeight,
    this.scrollMode = NotationScrollMode.horizontal,
  });

  @override
  State<StaffNotationView> createState() => _StaffNotationViewState();
}

class _StaffNotationViewState extends State<StaffNotationView> {
  late fmn.GrandStaff grandStaff;
  late fmn.PlaybackController playbackController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _buildNotation();
  }

  void _buildNotation() {
    final midiData = NotationBridge.recordingToMidiData(widget.recording);
    grandStaff = NotationBridge.midiDataToGrandStaff(midiData);

    final allNotes = [
      ...grandStaff.upperStaff.expand((m) => m.notes),
      ...grandStaff.lowerStaff.expand((m) => m.notes),
    ];

    playbackController = fmn.PlaybackController(
      notes: allNotes,
      beatsPerMinute: widget.recording.beatsPerMinute,
    );
  }


  @override
  void didUpdateWidget(StaffNotationView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.recording != widget.recording) {
      playbackController.dispose();
      _buildNotation();
    } else {
      final currentBeat = (widget.currentPosition / 60.0) *
          widget.recording.beatsPerMinute;
      playbackController.seekTo(currentBeat);

      if (widget.scrollMode == NotationScrollMode.horizontal) {
        _autoScroll(currentBeat);
      }
    }
  }

  void _autoScroll(double currentBeat) {
    const pixelsPerBeat = 80.0; // Adjust based on spacing
    final scrollOffset = currentBeat * pixelsPerBeat;
    const cursorOffset = 50.0;

    if (_scrollController.hasClients) {
      _scrollController.jumpTo(
        (scrollOffset - cursorOffset).clamp(
          0.0,
          _scrollController.position.maxScrollExtent,
        ),
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    playbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isHorizontal = widget.scrollMode == NotationScrollMode.horizontal;

    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withAlpha(76)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            width: 2000,
            child: fmn.NotationView(
              grandStaff: grandStaff,
              playbackController: playbackController,
              config: fmn.NotationConfig(
                staffSpaceSize: 8,  // Compact
                leftMargin: 120,
                measureSpacing: 25,
                useSystemLayout: false,
                systemHeight: 150,
                systemSpacing: 40,
                showMeasureNumbers: true,
                showBrace: true,
                grandStaffGap: 30,
                upperStaffHeight: 25,
                lowerStaffHeight: 25,
                enableBeaming: false,
                enableTieDetection: false,
                spacingEngine: fmn.SpacingPresets.uniform,
                showKeySignatureOnEachSystem: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}