import 'package:vocal_message/src/azure_blob/azblob_abstract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('azblob download audio', () async {
    final audioUint8List = await AzureBlobAbstract.downloadAudioFromAzure(
        '/audio-test/test/audio2.wav');
    // expect(files.first.path, 'test/audio.wav');
  });
  // SAVE it
}
