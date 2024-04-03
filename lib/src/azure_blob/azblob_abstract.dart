import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:vocal_message/src/azure_blob/audio_file_parser.dart';
import 'package:vocal_message/src/azure_blob/azblob_base.dart';
import 'package:flutter/foundation.dart';

abstract class AzureBlobAbstract {
  static String _connectionString = '';
  static setConnectionString(String val) {
    _connectionString = val;
  }

  static Future<List<AzureAudioFileParser>> fetchRemoteAudioFilesInfo(
      String folderPath, http.Client client) async {
    if (_connectionString.isEmpty) {
      debugPrint('Azure _connectionString isEmpty');
      return [];
    }
    final storage = AzureStorage.parse(_connectionString);

    try {
      final blobs = await storage.listBlobsRaw(folderPath, client);
      final response = await blobs.stream.bytesToString();
      final azureFiles = AzureAudioFileParser.parseXml(response);
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
      final streamedResponse = await storage.getBlob(wavFileLink, client);
      //await for await streamedResponse.stream.last
      // final d = await streamedResponse.stream.toBytes();
      // print('d.elementSizeInBytes ${d.elementSizeInBytes}');
      //streamedResponse.stream.toBytes();
      final response = await http.Response.fromStream(streamedResponse);
      return response.bodyBytes;
    } on AzureStorageException catch (ex) {
      debugPrint('AzureStorageException ${ex.message}');
      return Uint8List.fromList([]);
    } on http.ClientException {
      // catch Connection closed while receiving data
      return Uint8List.fromList([]);
    }
  }

  static Future<bool> uploadAudioWavToAzure(
      String filePath, String azureFolderFullPath, http.Client client) async {
    try {
      Uint8List content = await File(filePath).readAsBytes();
      final storage = AzureStorage.parse(_connectionString);
      final isDone = await storage.putBlob(azureFolderFullPath, client,
          bodyBytes: content, contentType: 'audio/wav');
      return isDone;
    } on AzureStorageException catch (ex) {
      debugPrint('AzureStorageException ${ex.message}');
      return false;
    } on http.ClientException catch (e) {
      if (e.message.contains('Connection closed while receiving data') ==
          false) {
        debugPrint(e.toString());
      }
      return false;
    }
  }

  static Future<bool> uploadJsonToAzure(
      String text, String azureFolderFullPath, http.Client client) async {
    final storage = AzureStorage.parse(_connectionString);
    try {
      await storage.putBlob(azureFolderFullPath, client,
          body: text, contentType: 'application/json');
      debugPrint('uploadJsonToAzure done');
      return true;
    } on AzureStorageException catch (ex) {
      debugPrint('AzureStorageException ${ex.message}');
      return false;
    }
  }
}
