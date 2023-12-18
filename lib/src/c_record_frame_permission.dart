// ignore: file_names
import 'dart:io';
import 'package:vocal_message/src/recorder_mobile_ui/record_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'recorder_desktop_ui/desktop_frame.dart';

class RecorderFrame extends StatelessWidget {
  const RecorderFrame({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
}
