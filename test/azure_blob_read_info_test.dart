import 'package:vocal_message/src/azure_blob/azblob_abstract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('azblob read', () async {
    final files =
        await AzureBlobAbstract.fetchRemoteAudioFilesInfo('/audio-test/test');
    expect(files.first.path, 'test/audio.wav');
  });
}
