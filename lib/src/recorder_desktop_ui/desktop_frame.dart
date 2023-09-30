import 'package:vocal_message/src/recorder_desktop_ui/audio_rec_desk_player.dart';
import 'package:vocal_message/src/recorder_desktop_ui/audio_recorder.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class RecorderDesktopFrame extends StatefulWidget {
  const RecorderDesktopFrame({Key? key}) : super(key: key);

  @override
  State<RecorderDesktopFrame> createState() => _RecorderDesktopFrameState();
}

class _RecorderDesktopFrameState extends State<RecorderDesktopFrame> {
  String? audioPath;
  bool show = false;
  bool showPlayer = false;
  FocusNode focusNode = FocusNode();
  bool sendButton = false;
  // List<MessageModel> messages = [];

  @override
  void initState() {
    showPlayer = false;
    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        setState(() {
          show = false;
        });
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: showPlayer
          ? AudioRecPlayer(
              source: audioPath!,
              onDoneOrDelete: () {
                setState(() => showPlayer = false);
              },
            )
          : AudioRecorderView(
              onStop: (path) {
                if (kDebugMode) print('Recorded file path: $path');
                setState(() {
                  audioPath = path;
                  showPlayer = true;
                });
              },
            ),
    );
  }
}
