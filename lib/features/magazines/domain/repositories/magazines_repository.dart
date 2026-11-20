import 'dart:typed_data';

import '../entities/magazine.dart';

abstract class MagazinesRepository {
  /// Magazines whose date range covers today, newest first.
  Future<List<Magazine>> fetchActiveMagazines();

  /// Every magazine, including upcoming and expired ones; for the admin.
  Future<List<Magazine>> fetchAllMagazines();

  /// Uploads the cover and PDF, then inserts the row. [coverFileName] and
  /// [pdfFileName] only supply the extensions and content types.
  Future<Magazine> createMagazine({
    required String title,
    required Uint8List coverBytes,
    required String coverFileName,
    required Uint8List pdfBytes,
    required String pdfFileName,
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<void> deleteMagazine(String id);
}
