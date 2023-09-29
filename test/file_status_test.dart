// TODO - test that fileStatus present locally and in Azure is displayed just right

import 'package:vocal_message/src/azure_blob/azblob_abstract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fileStatus', () async {
    final files =
        await AzureBlobAbstract.fetchRemoteAudioFilesInfo('/audio-test/test');
    files.first.path;
  });
}
