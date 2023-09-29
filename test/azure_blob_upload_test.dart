import 'package:vocal_message/src/azure_blob/azblob_abstract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('azblob upload', () async {
    final dd = await AzureBlobAbstract.uploadAudioWavToAzure(
        'test/audio2.wav', '/audio-test/test/audio2.wav');
    expect(dd, isTrue);
  });
}
