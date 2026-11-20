/// Customer → warehouse → driver.
enum OrderStatus {
  pending('pending'),
  preparing('preparing'),
  readyForDelivery('ready_for_delivery'),
  outForDelivery('out_for_delivery'),
  delivered('delivered'),
  cancelled('cancelled');

  const OrderStatus(this.value);

  /// The value stored in `orders.status`.
  final String value;

  /// [value] as one of the [values]' `value`s whichever way it was written:
  /// the app and warehouse store snake_case, the admin dashboard camelCase
  /// (`outForDelivery`). Values not known here come back lowercased with
  /// separators removed.
  static String normalize(String value) {
    final compact =
        value.trim().toLowerCase().replaceAll(RegExp(r'[\s_-]'), '');
    // Orders saved before the warehouse step used "processing".
    if (compact == 'processing') return preparing.value;
    // Some dashboards label a fresh order "new".
    if (compact == 'new') return pending.value;
    for (final status in values) {
      if (status.value.replaceAll('_', '') == compact) return status.value;
    }
    return compact;
  }

  /// Null for values the dashboard doesn't know about.
  static OrderStatus? fromValue(String value) {
    final normalized = normalize(value);
    for (final status in values) {
      if (status.value == normalized) return status;
    }
    return null;
  }
}
