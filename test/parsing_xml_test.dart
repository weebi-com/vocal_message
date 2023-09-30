import 'dart:io';

import 'package:vocal_message/src/azure_blob/audio_file_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parsing azure blob xml', () async {
    final xml = File('test/dummy.xml').readAsStringSync();

    final filesAzure = AzureAudioFileParser.parseXml(xml);
    expect(
        filesAzure.first,
        AzureAudioFileParser(
            'test/audio.wav', DateTime(2023, 09, 17, 22, 17, 53), 209920));
  });
}
