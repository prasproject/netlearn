/// Fallback when platform implementation is unavailable.
Future<String?> saveBytes({
  required List<int> bytes,
  required String fileName,
}) {
  throw UnsupportedError('Export file tidak didukung di platform ini.');
}

Future<void> openSavedFile(String path) {
  throw UnsupportedError('Buka file tidak didukung di platform ini.');
}

bool get isWebExport => false;
