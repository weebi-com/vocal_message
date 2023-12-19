import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:media_store_plus/media_store_plus.dart';
import 'package:vocal_message/src/azure_blob/audio_config.dart';

final mediaStorePlugin = MediaStore(); // android annoying storage

extension LocalPathDownloadedFile on String {
  String get localPathFull =>
      Globals.theirFilesDir.path + Platform.pathSeparator + this;
}

abstract class Globals {
  Globals._();
  static late http.Client client;
  static String locale = 'fr';
  static String documentPath = '';
  static String androidSupportDirPath = '';

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

  static late AppConfig _config;
  static set setAzureAudioConfig(AppConfig cg) => _config = cg;
  static AppConfig get config => _config;

  static const double borderRadius = 27;
  static const double defaultPadding = 8;
  static GlobalKey<AnimatedListState> audioListKey =
      GlobalKey<AnimatedListState>();
}
