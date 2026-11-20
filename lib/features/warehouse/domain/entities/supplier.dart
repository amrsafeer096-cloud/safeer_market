/// A supplier registered in Fujitsu (`sys_supplier`), read from `app_suppliers`.
class Supplier {
  const Supplier({required this.number, required this.name});

  final int number;
  final String name;

  String get label => '$number - $name';

  /// True when [query] is part of the supplier's name or number.
  bool matches(String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return true;
    return name.toLowerCase().contains(needle) ||
        number.toString().contains(needle);
  }
}
