import 'package:intl/intl.dart';
import 'package:xml/xml.dart';

class AzureAudioFile {
  final String path;
  final DateTime? creationTime;
  final int contentLength;
  //Content-Encoding />
//<Content-Language />
  const AzureAudioFile(this.path, this.creationTime, this.contentLength);
  String get fileName => path.split('/').last;

  static Iterable<AzureAudioFile> parseXml(String xml) {
    final filesAzure = <AzureAudioFile>[];

    final document = XmlDocument.parse(xml);
    final results = document.findElements('EnumerationResults').first;
    final blobsNode = results.findElements('Blobs').first;
    final blobs = blobsNode.findElements('Blob');
    for (final fileXml in blobs) {
      final path = fileXml.findElements('Name').first.text;
      final properties = fileXml.findElements('Properties').first;
      // properties
      final tempDateString =
          properties.findElements('Creation-Time').first.text;
      final formatter = DateFormat('EEE, d MMM yyyy HH:mm:ss');
      final creationTime = formatter.parse(tempDateString);
      final contentLength =
          int.parse(properties.findElements('Content-Length').first.text);
      final type = properties.findElements('Content-Type').first.text;
      if (path.isNotEmpty) {
        if (type == 'audio/wav' || type == 'audio/x-wav') {
          final fileAzure = AzureAudioFile(path, creationTime, contentLength);
          filesAzure.add(fileAzure);
        }
      }
    }
    return filesAzure;
  }

  @override
  String toString() =>
      'AudioFileFromAzure(path: $path, creationTime: ${creationTime?.toIso8601String()}, contentLength: $contentLength)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AzureAudioFile &&
        other.path == path &&
        other.creationTime == creationTime &&
        other.contentLength == contentLength;
  }

  @override
  int get hashCode =>
      path.hashCode ^ creationTime.hashCode ^ contentLength.hashCode;
}
