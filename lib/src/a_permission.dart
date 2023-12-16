// ignore: file_names
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:vocal_message/src/b_home_view.dart';

class VocalMainView extends StatelessWidget {
  final String title;
  const VocalMainView(this.title, {Key? key}) : super(key: key);

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
            return VocalMessagesAndRecorderView(title, snap.data!);
          }
        });
  }
}
