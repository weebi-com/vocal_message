// ignore: file_names
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:vocal_message/src/recorder_mobile_ui/record_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'recorder_desktop_ui/desktop_frame.dart';

Future<bool> checkPermission() async {
  const Permission permissionMic = Permission.microphone;
  final status = await permissionMic.status;
  if (status != PermissionStatus.granted) {
    final newStatus = await permissionMic.request();
    return newStatus == PermissionStatus.granted;
  } else {
    return true;
  }
}

class RecorderFrame extends StatelessWidget {
  const RecorderFrame({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
        future: checkPermission(),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return SizedBox(
                width: MediaQuery.of(context).size.width * 0.5,
                child: const CircularProgressIndicator());
          } else if (snap.hasError) {
            debugPrint('${snap.error}');
            return ColoredBox(
                color: Colors.pink,
                child: Text('mic permission error ${snap.error}'));
          } else if (snap.connectionState != ConnectionState.waiting &&
              !snap.hasData) {
            return const ColoredBox(
                color: Colors.purple, child: Text('no mic permission data'));
          } else if (snap.data == null) {
            return const ColoredBox(
                color: Colors.blue, child: Text(' mic permission  null'));
          } else {
            return snap.data! == false
                ? const Center(
                    child: Text('missing mic permission'),
                  )
                : Padding(
                    padding: const EdgeInsets.all(22.0),
                    child: (!kIsWeb && (Platform.isAndroid || Platform.isIOS))
                        ? const Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment
                                .end, // keep mic button on the right
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
