import 'dart:io';

import 'package:vocal_message/src/globals.dart';

enum SyncStatus {
  remoteNotSynced,
  localNotSynced,
  remoteSyncing,
  localSyncing,
  synced,
  localDefective,
}

abstract class FileSyncStatus {
  final SyncStatus status;
  final String filePath;
  const FileSyncStatus(this.status, this.filePath);

  DateTime get dateLastModif;

  @override
  toString() => '$status, $filePath';
}

extension NamesOnlyOnLocalPath on Iterable<String> {
  List<String> get namesOnly {
    final fileNamesOnly = <String>[];
    for (final localFile in this) {
      fileNamesOnly.add(localFile.split('/').last);
    }
    return fileNamesOnly;
  }
}

extension NameOnlyOnLocalPath on String {
  String get nameOnly => split('/').last;
}

class MyFileStatus implements FileSyncStatus {
  SyncStatus uploadStatus;
  final String localPath;

  MyFileStatus(this.uploadStatus, this.localPath);
  @override
  String get filePath => localPath;

  @override
  SyncStatus get status => uploadStatus;

  @override
  DateTime get dateLastModif => File(filePath).lastModifiedSync();

  @override
  toString() => '$runtimeType, $status, $filePath';

  MyFileStatus copyWith({SyncStatus? uploadStatus, String? localPath}) {
    return MyFileStatus(
      uploadStatus ?? this.uploadStatus,
      localPath ?? this.localPath,
    );
  }
}

class TheirFileStatus implements FileSyncStatus {
  static final defaultDate = DateTime(3000, 1, 1);
  SyncStatus downloadStatus;
  final String azurePath;
  final DateTime? creationTime;
  final int bytes;

  TheirFileStatus(
      this.downloadStatus, this.azurePath, this.creationTime, this.bytes);
  @override
  DateTime get dateLastModif => (creationTime ?? defaultDate).toLocal();

  String get localPathFull {
    if (downloadStatus != SyncStatus.synced) {
      return '';
    } else {
      return filePath.nameOnly.localPathFull;
    }
  }

  @override
  String get filePath => azurePath;

  @override
  SyncStatus get status => downloadStatus;

  @override
  toString() => '$runtimeType, $status, $filePath';

  TheirFileStatus copyWith(
      {SyncStatus? downloadStatus,
      String? azurePath,
      DateTime? creationTime,
      int? bytes}) {
    return TheirFileStatus(
      downloadStatus ?? this.downloadStatus,
      azurePath ?? this.azurePath,
      creationTime ?? this.creationTime,
      bytes ?? this.bytes,
    );
  }
}
