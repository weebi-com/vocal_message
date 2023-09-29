import 'dart:io';

import 'package:vocal_message/example/const.dart';
import 'package:vocal_message/src/azure_blob/audio_parser.dart';
import 'package:vocal_message/src/azure_blob/azblob_base.dart';
import 'package:flutter/foundation.dart';

abstract class AzureBlobAbstract {
  static const String _connectionString = connectionString;

  static Future<List<AzureAudioFile>> fetchRemoteAudioFilesInfo(
      String folderPath) async {
    final storage = AzureStorage.parse(_connectionString);

    try {
      final blobs = await storage.listBlobsRaw(folderPath);
      final response = await blobs.stream.bytesToString();
      final azureFiles = AzureAudioFile.parseXml(response);
      return azureFiles.toList();
    } on AzureStorageException catch (ex) {
      debugPrint('AzureStorageException ${ex.message}');
      return [];
    }
  }

  static Future<Uint8List> downloadAudioFromAzure(String wavFileLink) async {
    final storage = AzureStorage.parse(_connectionString);
    final file = await storage.getBlob(wavFileLink);
    Uint8List data = await file.stream.toBytes();
    return data;
  }

  static Future<bool> uploadJsonToAzure(
      String text, String azureFolderFullPath) async {
    final storage = AzureStorage.parse(_connectionString);
    try {
      await storage.putBlob(azureFolderFullPath,
          body: text, contentType: 'application/json');
      debugPrint('uploadJsonToAzure done');
      return true;
    } on AzureStorageException catch (ex) {
      debugPrint('AzureStorageException ${ex.message}');
      return false;
    }
  }

  static Future<bool> uploadAudioWavToAzure(
    String filePath,
    String azureFolderFullPath,
  ) async {
    try {
      Uint8List content = await File(filePath).readAsBytes();
      final storage = AzureStorage.parse(_connectionString);
      await storage.putBlob(azureFolderFullPath,
          bodyBytes: content, contentType: 'audio/wav');
      debugPrint('uploadAudioWavToAzure done');
      return true;
    } on AzureStorageException catch (ex) {
      debugPrint('AzureStorageException ${ex.message}');
      return false;
    }
  }
}
