// ignore: file_names
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:vocal_message/src/b_home_view.dart';
import 'package:vocal_message/src/android_storage/android_ext_storage.dart';

/// this view is only used for android
class VocalMainView extends StatelessWidget {
  final String title;
  const VocalMainView(this.title, {Key? key}) : super(key: key);

  Future<bool> checkAndroidStoragePermission() async {
    if (Platform.isAndroid) {
      return await canUseAndroidStorage();
    } else {
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Platform.isAndroid != false
        ? VocalMessagesAndRecorderView(title, true)
        : FutureBuilder<bool>(
            future: checkAndroidStoragePermission(),
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
                    color: Colors.purple,
                    child: Text('no mic permission data'));
              } else if (snap.data == null) {
                return const ColoredBox(
                    color: Colors.blue, child: Text(' mic permission  null'));
              } else {
                return VocalMessagesAndRecorderView(title, snap.data!);
              }
            });
  }
}
