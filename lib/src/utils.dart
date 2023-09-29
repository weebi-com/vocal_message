//import 'dart:async';
import 'dart:io';

import 'package:vocal_message/src/globals.dart';

List<String> fetchAudioFilesLocal() {
  String dirPath = Globals.documentPath;
  List<FileSystemEntity> files = Directory(dirPath).listSync();
  files.removeWhere((element) => !element.path.endsWith("wav"));
  files = files.reversed.toList();
  return files.map((e) => e.path).toList();
}
