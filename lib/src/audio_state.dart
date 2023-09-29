import 'dart:io';

import 'package:vocal_message/src/azure_blob/azblob_abstract.dart';
import 'package:vocal_message/src/globals.dart';
import 'package:vocal_message/src/file_status.dart';
import 'package:flutter/foundation.dart';

/// Choosing this method because using proper state management would be an
/// overkill for the scope of this project.
class AudioState {
  const AudioState._();
  // ignore: prefer_const_constructors
  static AllAudioFiles allAudioFiles = AllAudioFiles([], []);
}

Future<List<String>> fetchRemoteAudioFiles(String azurePath) async {
  final files = await AzureBlobAbstract.fetchRemoteAudioFilesInfo(azurePath);
  final fileNames = <String>[];
  for (final file in files) {
    fileNames.add(file.fileName);
    debugPrint(file.fileName);
  }
  return fileNames;
}

List<String> getAllLocalAudioFiles() {
  List<FileSystemEntity> files =
      Directory(Globals.documentPath).listSync(recursive: true);
  files.removeWhere((element) => !element.path.endsWith("wav"));
  files = files.reversed.toList();
  return files.map((e) => e.path).toList();
}

List<String> getOnlyMyLocalAudioFiles() {
  List<FileSystemEntity> files = Globals.myFilesDir.listSync(recursive: false);
  files.removeWhere((element) => !element.path.endsWith("wav"));
  files = files.reversed.toList();
  return files.map((e) => e.path).toList();
}

List<String> getOnlyTheirLocalAudioFiles() {
  List<FileSystemEntity> files =
      Globals.theirFilesDir.listSync(recursive: false);
  files.removeWhere((element) => !element.path.endsWith("wav"));
  files = files.reversed.toList();
  return files.map((e) => e.path).toList();
}

Future<AllAudioFiles> getLocalAudioFetchFilesAndSetStatus(
    String azurePath, bool isConnected) async {
  if (isConnected) {
    final allLocalFiles = getAllLocalAudioFiles();
    final allAudios = await fetchFilesAndSetStatus(azurePath, allLocalFiles);
    return allAudios;
  } else {
    return getLocalFilesAndStatusOnly();
  }
}

AllAudioFiles getLocalFilesAndStatusOnly() {
  final myFiles = <MyFileStatus>[];
  final theirFiles = <TheirFileStatus>[];
  final myLocalFiles = getOnlyMyLocalAudioFiles();
  for (final file in myLocalFiles) {
    final temp = MyFileStatus(SyncStatus.localNotSynced, file);
    myFiles.add(temp);
  }
  final theirLocalFiles = getOnlyTheirLocalAudioFiles();
  for (final file in theirLocalFiles) {
    final temp = TheirFileStatus(SyncStatus.synced, file);
    theirFiles.add(temp);
  }
  return AllAudioFiles(myFiles, theirFiles);
}

Future<AllAudioFiles> fetchFilesAndSetStatus(
    String azurePath, List<String> localFiles) async {
  final upFiles = <MyFileStatus>[];
  final downFiles = <TheirFileStatus>[];
  final remoteFilesUploads =
      await fetchRemoteAudioFiles(azurePath + '/uploads');
  final remoteFilesDownload =
      await fetchRemoteAudioFiles(azurePath + '/downloads');
  final remoteFiles = [...remoteFilesUploads, ...remoteFilesDownload];
  for (final localFile in localFiles) {
    if (remoteFiles.contains(localFile.nameOnly)) {
      // local file exists in azure
      final upFile = MyFileStatus(SyncStatus.synced, localFile);
      upFiles.add(upFile);
    } else {
      // local file does not exists in azure, should be synced
      final upFile = MyFileStatus(SyncStatus.localNotSynced, localFile);
      upFiles.add(upFile);
    }
  }
  for (final remoteFile in remoteFiles) {
    if (localFiles.namesOnly.contains(remoteFile)) {
      // remote file has already been downloaded from azure
      final downFile = TheirFileStatus(SyncStatus.synced, remoteFile);
      downFiles.add(downFile);
    } else {
      // remote file has not been downloaded from azure
      final downFile = TheirFileStatus(SyncStatus.remoteNotSynced, remoteFile);
      downFiles.add(downFile);
    }
  }
  debugPrint('upFiles ${upFiles.length}');
  return AllAudioFiles(upFiles, downFiles);
}

class AllAudioFiles {
  final List<MyFileStatus> myFiles;
  final List<TheirFileStatus> theirFiles;
  const AllAudioFiles(this.myFiles, this.theirFiles);

  List<FileSyncStatus> get all => [...myFiles, ...theirFiles];
}
