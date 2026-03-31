// Stub implementations for non-web platforms
// These are placeholders that will be replaced by download_helper_web.dart on web

void downloadCSVWeb(String csvContent, String fileName) {
  throw UnsupportedError('CSV download is only supported on web');
}

void downloadPDFWeb(List<int> bytes, String fileName) {
  throw UnsupportedError('PDF download is only supported on web');
}
