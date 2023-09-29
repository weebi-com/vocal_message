import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

extension LocalPathDownloadedFile on String {
  String get localPathFull =>
      Globals.theirFilesDir.path + Platform.pathSeparator + this;
}

abstract class Globals {
  Globals._();
  static late http.Client client;
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

  static String get azureMyFilesPath => '/audio-test/jimmy_jo/uploads';
  static String get azureTheirFilesPath => '/audio-test/jimmy_jo/downloads';

  // TODO make setter for containerName
  // TODO make setter for userFolder
  // TODO update my/theirFiles getters

  static const double borderRadius = 27;
  static const double defaultPadding = 8;
  static GlobalKey<AnimatedListState> audioListKey =
      GlobalKey<AnimatedListState>();
}
