import 'dart:io';

import 'package:external_path/external_path.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vocal_message/src/globals.dart';

class AndroidExtStorageSingleton {
  late String path;

  static final AndroidExtStorageSingleton _inst =
      AndroidExtStorageSingleton._internal();

  AndroidExtStorageSingleton._internal();

  factory AndroidExtStorageSingleton({required String path}) {
    _inst.path = path;
    return _inst;
  }
}

Future<bool> canUseAndroidExtStorage() async {
  final ext = await _getMyExtStoragePathAndroid();
  Globals.setAndroidConfig = AndroidExtStorageSingleton(path: ext);
  return ext.isNotEmpty;
}

// using globals here is not clean, but it enables dev to set their own folder name
bool setupAndroidExtFolders() {
  try {
    Globals.myFilesDir.createSync();
    Globals.theirFilesDir.createSync();
    return Globals.myFilesDir.existsSync() &&
        Globals.theirFilesDir.existsSync();
  } on FileSystemException catch (e) {
    debugPrint('android directory not create $e');
    return false;
  }
}

bool areAndroidExtFoldersAvailable() {
  try {
    final isMyExists = Directory(Globals.androidMyAudioFolderName).existsSync();
    final isTheirExists =
        Directory(Globals.androidMyAudioFolderName).existsSync();
    return isMyExists && isTheirExists;
  } on FileSystemException catch (e) {
    debugPrint('android directory not create $e');
    return false;
  }
}

Future<String> _getMyExtStoragePathAndroid() async {
  final isAllowed = await canReadStorage();
  if (!isAllowed) {
    return '';
  }
  try {
    final ext = await ExternalPath.getExternalStoragePublicDirectory(
        ExternalPath.DIRECTORY_MUSIC);
    return ext;
  } catch (e) {
    debugPrint('error getting ext storage path $e');
    return '';
  }
}

Future<bool> canReadStorage() async {
  Platform.operatingSystemVersion;
  const Permission _permissionAndroid13 = Permission.manageExternalStorage;
  final statusAndroid13 = await _permissionAndroid13.status;
  if (statusAndroid13 == PermissionStatus.granted) {
    return true;
  } else {
    final future = await _permissionAndroid13.request();
    if (future == PermissionStatus.granted) {
      return true;
    } else {
      const Permission _permission = Permission.storage;
      final status = await _permission.status;
      if (status == PermissionStatus.granted) {
        return true;
      } else {
        final future = await _permission.request();
        if (future == PermissionStatus.granted) {
          return true;
        } else {
          return false;
        }
      }
    }
  }
}
