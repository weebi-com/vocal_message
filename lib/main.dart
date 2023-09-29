import 'dart:io';

import 'package:vocal_message/src/globals.dart';
import 'package:vocal_message/src/home_page.dart';
// import 'package:vocal_message/src/routes.dart';
import 'package:vocal_message/src/theme.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppDocDirectory());
}

class AppDocDirectory extends StatelessWidget {
  const AppDocDirectory({super.key});

  @override
  Widget build(BuildContext context) {
    // watch out for web
    return FutureBuilder<Directory>(
        future: getApplicationDocumentsDirectory(),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const ColoredBox(color: Colors.black);
          } else if (snap.hasError) {
            debugPrint('${snap.error}');
            return ColoredBox(
                color: Colors.pink,
                child: Text('appDirectory error ${snap.error}'));
          } else if (snap.connectionState != ConnectionState.waiting &&
              !snap.hasData) {
            return const ColoredBox(
                color: Colors.purple, child: Text('no appDirectory'));
          } else if (snap.data == null) {
            return const ColoredBox(
                color: Colors.blue, child: Text('appDirectory null'));
          } else {
            Globals.setDocumentPath(snap.data!);
            return const MyApp();
          }
        });
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const HomePage(),
      title: 'Audio Chat',
      theme: AudioTheme.dartTheme(),
      // onGenerateRoute: AppRoutes.routes,
    );
  }
}
