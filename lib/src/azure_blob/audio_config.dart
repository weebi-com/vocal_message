class AzureAudioConfig {
  late String connectionString;
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

  String get azureRootPath => '/' + containerName + '/' + userFolderName;
  String get azureMyFilesPath =>
      '/' + containerName + '/' + userFolderName + '/uploads';

  String get azureTheirFilesPath =>
      '/' + containerName + '/' + userFolderName + '/downloads';
}
