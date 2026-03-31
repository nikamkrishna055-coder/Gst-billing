import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

// Conditional import - imports download_helper_web on web, stub on mobile
import 'download_helper_stub.dart'
    if (dart.library.html) 'download_helper_web.dart'
    as dl;

/// Downloads CSV file - works on both web and mobile
///
/// On Web: Triggers browser download
/// On Mobile: Uses share_plus for native sharing
Future<void> downloadCSV(String csvContent, String fileName) async {
  if (kIsWeb) {
    dl.downloadCSVWeb(csvContent, fileName);
  } else {
    await _downloadCSVMobile(csvContent, fileName);
  }
}

Future<void> _downloadCSVMobile(String csvContent, String fileName) async {
  try {
    // Get the temporary directory
    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/$fileName';

    // Write CSV content to file
    final file = File(filePath);
    await file.writeAsString(csvContent, encoding: utf8);

    // Share the file
    await Share.shareXFiles(
      [XFile(filePath)],
      subject: 'CSV Export',
      text: 'CSV data has been exported',
    );
  } catch (e) {
    rethrow;
  }
}
