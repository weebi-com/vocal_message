import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:voc_up/home_page.dart';
import 'package:voc_up/secret.dart';
import 'package:voc_up/theme.dart';

import 'package:vocal_message/azure_blob2.dart';
import 'package:vocal_message/logic.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // pass azure connection string below
  // it looks like DefaultEndpointsProtocol=https;AccountName=...
  AzureBlobAbstract.setConnectionString(azureConn);

  // set the container used in azure blob and the user folder
  VocalMessagesConfig.setAzureAudioConfig = AzureBlobConfig(
      containerName: 'audio-test', userFolderName: 'vocup_test_user');

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
            VocalMessagesConfig.setDocumentPath(snap.data!);
            return const MyApp();
          }
        });
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  static const Iterable<LocalizationsDelegate<dynamic>> delegates = [
    GlobalWidgetsLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];
  @override
  Widget build(BuildContext context) {
    // set-up local here (default is fr)
    VocalMessagesConfig.locale = 'fr';

    return MaterialApp(
      home: const HomePage(),
      locale: const Locale('fr'),
      localizationsDelegates: delegates,
      supportedLocales: const [
        Locale('fr'),
        Locale('en'),
        Locale('es'),
      ],
      title: "Voc'up",
      theme: AudioTheme.dartTheme(),
    );
  }
}
