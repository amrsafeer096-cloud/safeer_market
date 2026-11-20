import '../../domain/entities/magazine.dart';

/// Maps a `magazines` row to and from [Magazine].
class MagazineModel {
  const MagazineModel._();

  static Magazine fromJson(Map<String, dynamic> json) {
    return Magazine(
      id: json['id'].toString(),
      title: (json['title'] as String?)?.trim() ?? '',
      coverImageUrl: (json['cover_image_url'] as String?) ?? '',
      pdfUrl: (json['pdf_url'] as String?) ?? '',
      startDate: _parseDate(json['start_date']) ?? DateTime.now(),
      endDate: _parseDate(json['end_date']) ?? DateTime.now(),
      createdAt: _parseDate(json['created_at']),
    );
  }

  /// The columns of a new row; the database fills `id` and `created_at`.
  static Map<String, dynamic> toInsertJson({
    required String title,
    required String coverImageUrl,
    required String pdfUrl,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return {
      'title': title,
      'cover_image_url': coverImageUrl,
      'pdf_url': pdfUrl,
      'start_date': dateOnly(startDate),
      'end_date': dateOnly(endDate),
    };
  }

  /// `yyyy-MM-dd`, what a Postgres `date` column takes and returns.
  static String dateOnly(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)}';
  }

  static DateTime? _parseDate(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }
}
