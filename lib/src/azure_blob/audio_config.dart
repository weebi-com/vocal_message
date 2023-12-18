class AppConfig {
  late String azureContainerName;
  late String azureUserFolderName;
  late String androidAudioName;
  static final AppConfig _inst = AppConfig._internal();

  AppConfig._internal();

  factory AppConfig(
      {required String containerName,
      required String userFolderName,
      String androidAudioName = 'vocal_message'}) {
    _inst.azureContainerName = containerName;
    _inst.azureUserFolderName = userFolderName;
    _inst.androidAudioName = androidAudioName;
    return _inst;
  }

  String get rootPath => '/' + azureContainerName + '/' + azureUserFolderName;
  String get myFilesPath =>
      '/' + azureContainerName + '/' + azureUserFolderName + '/sent_by_user';

  String get theirFilesPath =>
      '/' + azureContainerName + '/' + azureUserFolderName + '/loaded_by_admin';
}
