import 'dart:convert';
import 'dart:html' as html;

/// Web-specific implementation of CSV download
void downloadCSVWeb(String csvContent, String fileName) {
  try {
    final bytes = utf8.encode(csvContent);
    final blob = html.Blob([bytes], 'text/csv;charset=utf-8;');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..style.display = 'none';
    html.document.body?.append(anchor);
    anchor.click();
    html.Url.revokeObjectUrl(url);
    anchor.remove();
  } catch (e) {
    rethrow;
  }
}

/// Web-specific implementation of PDF download
void downloadPDFWeb(List<int> bytes, String fileName) {
  try {
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..style.display = 'none';
    html.document.body?.append(anchor);
    anchor.click();
    html.Url.revokeObjectUrl(url);
    anchor.remove();
  } catch (e) {
    rethrow;
  }
}
