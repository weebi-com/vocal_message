import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:vocal_message/src/azure_blob/azblob_config.dart';

extension LocalPathDownloadedFile on String {
  String get localPathFull =>
      VocalMessagesConfig.theirFilesDir.path + Platform.pathSeparator + this;
}

abstract class VocalMessagesConfig {
  VocalMessagesConfig._();
  static late http.Client client;
  static String locale = 'fr';
  static String documentPath = '';
  static String appName = '';

  static void setDocumentPath(Directory dir) {
    documentPath = dir.path;
    if (theirFilesDir.existsSync() == false) {
      Directory(theirFilesDir.path).createSync();
    }
    if (myFilesDir.existsSync() == false) {
      Directory(myFilesDir.path).createSync();
    }
  }

  static void setAppName(String _name) {
    appName = _name;
  }

  static Directory get theirFilesDir => Directory(documentPath +
      Platform.pathSeparator +
      appName +
      '_' +
      'DO_NOT_DELETE_their');

  static Directory get myFilesDir => Directory(documentPath +
      Platform.pathSeparator +
      appName +
      '_' +
      'DO_NOT_DELETE_my');

  static late AzureBlobConfig _config;
  static set setAzureAudioConfig(AzureBlobConfig cg) => _config = cg;
  static AzureBlobConfig get config => _config;

  static const double borderRadius = 27;
  static const double defaultPadding = 8;
  static GlobalKey<AnimatedListState> audioListKey =
      GlobalKey<AnimatedListState>();
}
