// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void downloadCsvFile(String csvData, String fileName) {
  final blob = html.Blob([csvData], 'text/csv;charset=utf-8');
  final url = html.Url.createObjectUrlFromBlob(blob);

  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();

  anchor.remove();
  html.Url.revokeObjectUrl(url);
}