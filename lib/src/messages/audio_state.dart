import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:vocal_message/src/azure_blob/audio_file_parser.dart';
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

Future<List<AzureAudioFileParser>> fetchRemoteAudioFiles(
    String azurePath, http.Client client) async {
  final files =
      await AzureBlobAbstract.fetchRemoteAudioFilesInfo(azurePath, client);
  return files;
}

List<String> getOnlyMyLocalAudioFiles() {
  List<FileSystemEntity> files =
      VocalMessagesConfig.myFilesDir.listSync(recursive: false);
  files.removeWhere((element) => !element.path.endsWith("wav"));
  files = files.reversed.toList();
  return files.map((e) => e.path).toList();
}

List<String> getOnlyTheirLocalAudioFiles() {
  List<FileSystemEntity> files =
      VocalMessagesConfig.theirFilesDir.listSync(recursive: false);
  files.removeWhere((element) => !element.path.endsWith("wav"));
  files = files.reversed.toList();
  return files.map((e) => e.path).toList();
}

Future<AllAudioFiles> getLocalAudioFetchFilesAndSetStatus(
    bool isConnected) async {
  if (isConnected) {
    final allAudios =
        await fetchFilesAndSetStatus(VocalMessagesConfig.config.rootPath);
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
  for (final filePath in theirLocalFiles) {
    final temp = TheirFileStatus(
        SyncStatus.synced, filePath, File(filePath).lastModifiedSync(), 0);
    theirFiles.add(temp);
  }
  return AllAudioFiles(myFiles, theirFiles);
}

Future<AllAudioFiles> fetchFilesAndSetStatus(String azurePath) async {
  final client = http.Client();
  final myFiles = <MyFileStatus>[];
  final theirFiles = <TheirFileStatus>[];
  final myRemoteFiles = await fetchRemoteAudioFiles(
      VocalMessagesConfig.config.myFilesPath, client);
  final myLocalFiles = getOnlyMyLocalAudioFiles();
  for (final localFile in myLocalFiles) {
    if (myRemoteFiles.filesNameOnly.contains(localFile.nameOnly)) {
      // local file exists in azure
      final upFile = MyFileStatus(SyncStatus.synced, localFile);
      myFiles.add(upFile);
    } else {
      // local file does not exists in azure, should be synced
      final upFile = MyFileStatus(SyncStatus.localNotSynced, localFile);
      myFiles.add(upFile);
    }
  }
  debugPrint('myFiles ${myFiles.length}');

  final client2 = http.Client();

  final theirLocalFiles = getOnlyTheirLocalAudioFiles();

  final theirRemoteFiles = await fetchRemoteAudioFiles(
      VocalMessagesConfig.config.theirFilesPath, client2);
  debugPrint('theirRemoteFiles ${theirRemoteFiles.length}');
  for (final remoteFile in theirRemoteFiles) {
    if (theirLocalFiles.namesOnly.contains(remoteFile.fileName)) {
      // remote file has already been downloaded from azure
      final downFile = TheirFileStatus(
        SyncStatus.synced,
        remoteFile.fileName,
        remoteFile.creationTime,
        remoteFile.contentLength,
      );
      theirFiles.add(downFile);
    } else {
      // remote file has not been downloaded from azure
      // debugPrint('remoteFile $remoteFile');
      final downFile = TheirFileStatus(
        SyncStatus.remoteNotSynced,
        remoteFile.fileName,
        remoteFile.creationTime,
        remoteFile.contentLength,
      );
      theirFiles.add(downFile);
    }
  }
  debugPrint('theirFiles ${theirFiles.length}');
  return AllAudioFiles(myFiles, theirFiles);
}

class AllAudioFiles {
  final List<MyFileStatus> myFiles;
  final List<TheirFileStatus> theirFiles;
  const AllAudioFiles(this.myFiles, this.theirFiles);

  List<FileSyncStatus> get all => [...myFiles, ...theirFiles]
    ..sort((a, b) => a.dateLastModif.compareTo(b.dateLastModif));
}
