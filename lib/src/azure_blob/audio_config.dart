class AzureAudioConfig {
  late String containerName;
  late String userFolderName;

  static final AzureAudioConfig _inst = AzureAudioConfig._internal();

  AzureAudioConfig._internal();

  factory AzureAudioConfig(
      {required String containerName, required String userFolderName}) {
    _inst.containerName = containerName;
    _inst.userFolderName = userFolderName;
    return _inst;
  }

  String get rootPath => '/' + containerName + '/' + userFolderName;
  String get myFilesPath =>
      '/' + containerName + '/' + userFolderName + '/uploads';

  String get theirFilesPath =>
      '/' + containerName + '/' + userFolderName + '/downloads';
}
