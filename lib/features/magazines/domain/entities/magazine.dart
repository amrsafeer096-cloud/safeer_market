/// A promotional magazine: a cover, a PDF and the dates it is on offer.
class Magazine {
  const Magazine({
    required this.id,
    required this.title,
    required this.coverImageUrl,
    required this.pdfUrl,
    required this.startDate,
    required this.endDate,
    this.createdAt,
  });

  final String id;
  final String title;
  final String coverImageUrl;
  final String pdfUrl;

  /// First day (inclusive) the magazine is shown to customers.
  final DateTime startDate;

  /// Last day (inclusive) the magazine is shown to customers.
  final DateTime endDate;

  final DateTime? createdAt;

  /// Whether [day] falls within [startDate]..[endDate], by calendar date.
  bool isActiveOn(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    final first = DateTime(startDate.year, startDate.month, startDate.day);
    final last = DateTime(endDate.year, endDate.month, endDate.day);
    return !date.isBefore(first) && !date.isAfter(last);
  }

  bool get isUpcoming => DateTime.now().isBefore(
        DateTime(startDate.year, startDate.month, startDate.day),
      );

  bool get isExpired => DateTime.now().isAfter(
        DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59),
      );
}
