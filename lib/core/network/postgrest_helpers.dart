import 'package:supabase_flutter/supabase_flutter.dart';

/// Most rows PostgREST returns per request (the project's max-rows).
const postgrestMaxRows = 1000;

/// True when an RPC function isn't in the database yet, i.e. its migration
/// hasn't been applied.
bool isMissingFunction(PostgrestException error) =>
    error.code == 'PGRST202' || error.code == '404';

/// True when a query names a column the table doesn't have.
bool isMissingColumn(PostgrestException error) => error.code == '42703';

extension InStockFilter<T> on PostgrestFilterBuilder<T> {
  /// Same rule as `Product.inStock`: `is_active` not false (null counts as
  /// active) and `stock_quantity` above zero.
  PostgrestFilterBuilder<T> inStock() =>
      not('is_active', 'is', false).gt('stock_quantity', 0);
}

extension WithImageFilter<T> on PostgrestFilterBuilder<T> {
  /// Same rule as `Product.hasValidImageUrl`: [column] is an http(s) link.
  /// The regex also rejects a bare 'https://'; the plain checks before it
  /// keep null, blank and 'null' out even where it can't use an index.
  PostgrestFilterBuilder<T> withImage({String column = 'image_url'}) =>
      not(column, 'is', null)
          .neq(column, '')
          .neq(column, 'null')
          .ilike(column, 'http%')
          .filter(column, 'imatch', r'^\s*https?://[^\s/]');

  /// [withImage] unless [includeWithoutImage] (admins see every product).
  PostgrestFilterBuilder<T> withImageUnless(
    bool includeWithoutImage, {
    String column = 'image_url',
  }) =>
      includeWithoutImage ? this : withImage(column: column);
}
