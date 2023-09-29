enum SyncStatus {
  remoteNotSynced,
  localNotSynced,
  syncing,
  synced,
}

abstract class FileSyncStatus {
  final SyncStatus status;
  final String filePath;
  const FileSyncStatus(this.status, this.filePath);
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
}

class TheirFileStatus implements FileSyncStatus {
  SyncStatus downloadStatus;
  final String azurePath;
  TheirFileStatus(this.downloadStatus, this.azurePath);

  @override
  String get filePath => azurePath;

  @override
  SyncStatus get status => downloadStatus;
}
