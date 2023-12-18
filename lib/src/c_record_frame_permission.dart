// ignore: file_names
import 'dart:io';
import 'package:record/record.dart';
import 'package:vocal_message/src/recorder_mobile_ui/record_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'recorder_desktop_ui/desktop_frame.dart';

// AudioRecorder().hasPermission(); // below seems redundant with a_permission
// but keep it here yet
class RecorderFrame extends StatelessWidget {
  const RecorderFrame({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
        future: AudioRecorder()
            .hasPermission(), // check it before displaying button otherwise weird behaviour first time
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return SizedBox(
                width: MediaQuery.of(context).size.width * 0.5,
                child: const CircularProgressIndicator());
          } else if (snap.hasError) {
            debugPrint('${snap.error}');
            return ColoredBox(
                color: Colors.pink,
                child: Text('audio permission error ${snap.error}'));
          } else if (snap.connectionState != ConnectionState.waiting &&
              !snap.hasData) {
            return const ColoredBox(
                color: Colors.purple, child: Text('no audio permission data'));
          } else if (snap.data == null) {
            return const ColoredBox(
                color: Colors.blue, child: Text('audio permission  null'));
          } else {
            return Padding(
              padding: const EdgeInsets.all(22.0),
              child: (!kIsWeb && (Platform.isAndroid || Platform.isIOS))
                  ? const Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment:
                          MainAxisAlignment.end, // keep mic button on the right
                      children: [
                        RecorderMobileView(),
                      ],
                    )
                  : const RecorderDesktopFrame(),
            );
          }
        });
  }
}
