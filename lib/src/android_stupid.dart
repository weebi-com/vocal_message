import 'package:external_path/external_path.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

Future<String> getExtStoragePathAndroid() async {
  final isAllowed = await canReadStorage();

  if (!isAllowed) {
    return '';
  }
  try {
    final ext = await ExternalPath.getExternalStoragePublicDirectory(
        ExternalPath.DIRECTORY_DOCUMENTS);
    return ext;
  } catch (e) {
    debugPrint('error getting ext storage path $e');
    return '';
  }
}

Future<bool> canReadStorage() async {
  {
    final Permission _permission = Permission.storage;

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

Future<bool> canReadExtStorage() async {
  const _permissionE = Permission.manageExternalStorage;

  final status = await _permissionE.status;
  if (status != PermissionStatus.granted) {
    final future = await _permissionE.request();
    if (future != PermissionStatus.granted) {
      return false;
    }
  } else {
    return true;
  }
  return true;
}
