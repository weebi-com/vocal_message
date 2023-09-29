import 'package:vocal_message/src/globals.dart';

enum SyncStatus {
  remoteNotSynced,
  localNotSynced,
  remoteSyncing,
  localSyncing,
  synced,
}

abstract class FileSyncStatus {
  final SyncStatus status;
  final String filePath;
  const FileSyncStatus(this.status, this.filePath);

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
  toString() => '$runtimeType, $status, $filePath';

  MyFileStatus copyWith({SyncStatus? uploadStatus, String? localPath}) {
    return MyFileStatus(
        uploadStatus ?? this.uploadStatus, localPath ?? this.localPath);
  }
}

class TheirFileStatus implements FileSyncStatus {
  SyncStatus downloadStatus;
  final String azurePath;
  TheirFileStatus(this.downloadStatus, this.azurePath);

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

  TheirFileStatus copyWith({SyncStatus? downloadStatus, String? azurePath}) {
    return TheirFileStatus(
        downloadStatus ?? this.downloadStatus, azurePath ?? this.azurePath);
  }
}
