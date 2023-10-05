// ignore: file_names
import 'package:vocal_message/src/android_ext/android_ext_storage.dart';
import 'package:flutter/material.dart';

class AndroidExtStorageWidget extends StatelessWidget {
  final Widget child;
  const AndroidExtStorageWidget(this.child, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
        future: canUseAndroidExtStorage(),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return SizedBox(
                width: MediaQuery.of(context).size.width * 0.5,
                child: const CircularProgressIndicator());
          } else if (snap.hasError) {
            debugPrint('${snap.error}');
            return ColoredBox(
                color: Colors.pink,
                child:
                    Text('android ext storage permission error ${snap.error}'));
          } else if (snap.connectionState != ConnectionState.waiting &&
              !snap.hasData) {
            return const ColoredBox(
                color: Colors.purple,
                child: Text('no android ext storage permission data'));
          } else if (snap.data == null) {
            return const ColoredBox(
                color: Colors.blue,
                child: Text('android ext storage permission  null'));
          } else {
            return child;
          }
        });
  }
}
