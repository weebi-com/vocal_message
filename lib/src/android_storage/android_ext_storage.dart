import 'package:permission_handler/permission_handler.dart';
import 'package:vocal_message/src/globals.dart';
import 'package:path_provider/path_provider.dart';

Future<bool> canUseAndroidStorage() async {
  if ((await mediaStorePlugin.getPlatformSDKInt()) >= 33) {
    // permissions.add(Permission.photos);
    // permissions.add(Permission.videos);
    if (await Permission.audio.isGranted == false) {
      final status = await Permission.audio.request();
      if (status != PermissionStatus.granted) {
        return false;
      }
    }
  } else {
    if (await Permission.storage.isGranted == false) {
      final storageStatus = await Permission.storage.request();
      if (storageStatus != PermissionStatus.granted) {
        return false;
      }
    }
  }
  final supportDir = await getApplicationSupportDirectory();
  Globals.androidSupportDirPath = supportDir.path;
  return true;
}
