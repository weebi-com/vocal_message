class AzureBlobConfig {
  late String azureContainerName;
  late String azureUserFolderName;
  static final AzureBlobConfig _inst = AzureBlobConfig._internal();

  AzureBlobConfig._internal();

  factory AzureBlobConfig(
      {required String containerName,
      required String userFolderName,
      String appName = 'vocal_message'}) {
    _inst.azureContainerName = containerName;
    _inst.azureUserFolderName = userFolderName;
    return _inst;
  }

  String get rootPath => '/' + azureContainerName + '/' + azureUserFolderName;
  String get myFilesPath =>
      '/' + azureContainerName + '/' + azureUserFolderName + '/sent_by_user';

  String get theirFilesPath =>
      '/' + azureContainerName + '/' + azureUserFolderName + '/loaded_by_admin';
}
