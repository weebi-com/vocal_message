import 'dart:io';

import 'package:flutter/cupertino.dart';

extension LocalPathDownloadedFile on String {
  String get localPathFull =>
      Globals.theirFilesDir.path + Platform.pathSeparator + this;
}

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
      Directory(documentPath + Platform.pathSeparator + 'their');
  static Directory get myFilesDir =>
      Directory(documentPath + Platform.pathSeparator + 'my');

  static const double borderRadius = 27;
  static const double defaultPadding = 8;
  static GlobalKey<AnimatedListState> audioListKey =
      GlobalKey<AnimatedListState>();
}
