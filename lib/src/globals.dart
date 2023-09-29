import 'dart:io';

import 'package:flutter/cupertino.dart';

abstract class Globals {
  Globals._();
  static String documentPath = '';
  static void setDocumentPath(Directory dir) {
    documentPath = dir.path;
    if (theirFilesDir.existsSync() == false) {
      Directory(theirFilesDir.path).createSync();
    }
    if (myFilesDir.existsSync() == false) {
      Directory(myFilesDir.path).createSync();
    }
  }

  static Directory get theirFilesDir =>
      Directory(documentPath + Platform.pathSeparator + 'up');
  static Directory get myFilesDir =>
      Directory(documentPath + Platform.pathSeparator + 'down');

  static const double borderRadius = 27;
  static const double defaultPadding = 8;
  static GlobalKey<AnimatedListState> audioListKey =
      GlobalKey<AnimatedListState>();
}
