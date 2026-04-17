// ignore: avoid_web_libraries_in_flutter
import 'package:web/web.dart' as web;
import 'dart:js_interop';

void downloadCsvFile(String csvData, String fileName) {
  final blob = web.Blob([csvData.toJS].toJS, web.BlobPropertyBag(type: 'text/csv;charset=utf-8'));
  final url = web.URL.createObjectURL(blob);

  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName
    ..click();

  anchor.remove();
  web.URL.revokeObjectURL(url);
}