import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:vocal_message/example/const.dart';
import 'package:vocal_message/src/azure_blob/audio_parser.dart';
import 'package:vocal_message/src/azure_blob/azblob_base.dart';
import 'package:flutter/foundation.dart';

abstract class AzureBlobAbstract {
  static const String _connectionString = connectionString;

  static Future<List<AzureAudioFile>> fetchRemoteAudioFilesInfo(
      String folderPath, http.Client client) async {
    final storage = AzureStorage.parse(_connectionString);

    try {
      final blobs = await storage.listBlobsRaw(folderPath, client);
      final response = await blobs.stream.bytesToString();
      final azureFiles = AzureAudioFile.parseXml(response);
      return azureFiles.toList();
    } on AzureStorageException catch (ex) {
      debugPrint('AzureStorageException ${ex.message}');
      return [];
    }
  }

  static Future<Uint8List> downloadAudioFromAzure(
      String wavFileLink, http.Client client) async {
    final storage = AzureStorage.parse(_connectionString);
    try {
      print('wavFileLink $wavFileLink');
      final streamedResponse = await storage.getBlob(wavFileLink, client);
      print('streamedResponse.contentLength ${streamedResponse.contentLength}');
      // Uint8List data = await file.stream.toBytes();
      // final response = await http.Response.fromStream(file);

      return await streamedResponse.stream.toBytes();
    } on AzureStorageException catch (ex) {
      debugPrint('AzureStorageException ${ex.message}');
      return Uint8List.fromList([]);
    }
  }

  static Future<bool> uploadJsonToAzure(
      String text, String azureFolderFullPath, http.Client client) async {
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
