import 'package:vocal_message/src/azure_blob/azblob_abstract.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  test('azblob download audio', () async {
    final client = http.Client();
    final audioUint8List = await AzureBlobAbstract.downloadAudioFromAzure(
        '/audio-test/test/audio2.wav', client);
    // expect(files.first.path, 'test/audio.wav');
  });
  // SAVE it
}
