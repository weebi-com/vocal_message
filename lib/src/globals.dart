import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:vocal_message/src/android_ext/android_ext_storage.dart';
import 'package:vocal_message/src/azure_blob/audio_config.dart';

extension LocalPathDownloadedFile on String {
  String get localPathFull =>
      Globals.theirFilesDir.path + Platform.pathSeparator + this;
}

abstract class Globals {
  Globals._();
  static late http.Client client;
  static String locale = 'fr';
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

  static Directory get theirFilesDir {
    if (Platform.isAndroid) {
      if (androidExtStorage.path.isNotEmpty &&
          config.androidAudioName.isNotEmpty) {
        return Directory(
            '${androidExtStorage.path}/${Globals.androidTheirAudioFolderName}');
      } else {
        debugPrint('cannot YET use android ext Storage stick to docPath');
        return Directory(documentPath + Platform.pathSeparator + 'their');
      }
    } else {
      return Directory(documentPath + Platform.pathSeparator + 'their');
    }
  }

  static Directory get myFilesDir {
    if (Platform.isAndroid) {
      if (androidExtStorage.path.isNotEmpty &&
          config.androidAudioName.isNotEmpty) {
        return Directory(
            '${androidExtStorage.path}/${Globals.androidMyAudioFolderName}');
      } else {
        debugPrint('cannot YET use android ext Storage stick to docPath');
        return Directory(documentPath + Platform.pathSeparator + 'their');
      }
    } else {
      return Directory(documentPath + Platform.pathSeparator + 'their');
    }
  }

  ///
  /// android specific
  /// saving in two different folders because music/audio is flat
  /// (not possible to save folders within folders in it)
  static AndroidExtStorageSingleton _androidExtStorage =
      AndroidExtStorageSingleton(path: '');
  static set setAndroidConfig(AndroidExtStorageSingleton val) =>
      _androidExtStorage = val;
  static AndroidExtStorageSingleton get androidExtStorage => _androidExtStorage;
  static String get androidMyAudioFolderName => config.androidAudioName + '_my';
  static String get androidTheirAudioFolderName =>
      config.androidAudioName + '_their';

  static late AppConfig _config;
  static set setAzureAudioConfig(AppConfig cg) => _config = cg;
  static AppConfig get config => _config;

  static const double borderRadius = 27;
  static const double defaultPadding = 8;
  static GlobalKey<AnimatedListState> audioListKey =
      GlobalKey<AnimatedListState>();
}
