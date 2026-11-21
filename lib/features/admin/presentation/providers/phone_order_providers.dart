import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/supabase_providers.dart';
import '../../../../core/notifications/order_push_dispatcher.dart';
import '../../../catalog/domain/main_categories.dart';
import '../../../cart/domain/weight_options.dart';
import '../../../home/domain/entities/product.dart';
import '../../data/repositories/supabase_phone_orders_repository.dart';
import '../../domain/phone_order.dart';
import '../../domain/repositories/phone_orders_repository.dart';
import 'system_admin_providers.dart';

final phoneOrdersRepositoryProvider = Provider<PhoneOrdersRepository>((ref) {
  return SupabasePhoneOrdersRepository(ref.watch(supabaseClientProvider));
});

/// Callers matching what was typed in «ابحث برقم الهاتف أو اسم العميل».
final phoneOrderCustomersProvider = FutureProvider.autoDispose
    .family<List<PhoneOrderCustomer>, String>((ref, query) {
  return ref.watch(phoneOrdersRepositoryProvider).searchCustomers(query);
});

typedef PhoneOrderProductQuery = ({String text, MainCategory? category});

final phoneOrderProductsProvider = FutureProvider.autoDispose
    .family<List<Product>, PhoneOrderProductQuery>((ref, query) {
  return ref
      .watch(phoneOrdersRepositoryProvider)
      .searchProducts(query.text, category: query.category);
});

/// Delivery zones of a city, for the new-customer address form.
final phoneOrderAreasProvider = FutureProvider.autoDispose
    .family<List<PhoneOrderArea>, String?>((ref, city) {
  return ref.watch(phoneOrdersRepositoryProvider).fetchAreas(city: city);
});

/// The governorates and their cities offered in the address form.
class ZoneGeo {
  const ZoneGeo(this.citiesByGovernorate);

  /// Cairo only, until zones are added in «إدارة النظام ← المناطق».
  static const fallback = ZoneGeo({
    'القاهرة': ['مدينة نصر', 'مصر الجديدة', 'التجمع الخامس'],
  });

  final Map<String, List<String>> citiesByGovernorate;

  List<String> get governorates => citiesByGovernorate.keys.toList();

  List<String> citiesOf(String? governorate) =>
      citiesByGovernorate[governorate] ?? const [];
}

/// Governorate → city lists from the active delivery zones (`areas`), so
/// the address dropdowns follow «المناطق».
final phoneOrderGeoProvider = FutureProvider.autoDispose<ZoneGeo>((ref) async {
  final zones = await ref.watch(systemAdminServiceProvider).zones();
  final map = <String, List<String>>{};
  for (final zone in zones.where((z) => z.isActive)) {
    final cities = map.putIfAbsent(zone.governorate, () => []);
    if (!cities.contains(zone.city)) cities.add(zone.city);
  }
  return map.isEmpty ? ZoneGeo.fallback : ZoneGeo(map);
});

/// Picks the InstaPay transfer screenshot (overridden in tests).
final phoneOrderReceiptPickerProvider =
    Provider<Future<PaymentReceiptImage?> Function()>((ref) {
  return () async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 2000,
    );
    if (picked == null) return null;
    final bytes = await picked.readAsBytes();
    if (bytes.isEmpty) return null;
    final name = picked.name.trim().isEmpty
        ? 'instapay_receipt.jpg'
        : picked.name.trim();
    final lower = name.toLowerCase();
    final contentType = switch (null) {
      _ when lower.endsWith('.png') => 'image/png',
      _ when lower.endsWith('.webp') => 'image/webp',
      _ when lower.endsWith('.gif') => 'image/gif',
      _ when lower.endsWith('.heic') => 'image/heic',
      _ => 'image/jpeg',
    };
    return PaymentReceiptImage(
      bytes: bytes,
      fileName: name,
      contentType: contentType,
    );
  };
});

final phoneOrderControllerProvider =
    NotifierProvider<PhoneOrderController, PhoneOrderState>(
  PhoneOrderController.new,
);

/// Past purchases for the locked-in caller (keyed by [PhoneOrderCustomer.key]).
final phoneOrderCustomerHistoryProvider = FutureProvider.autoDispose
    .family<CustomerPurchaseHistory, String>((ref, customerKey) async {
  final customer = ref.watch(
    phoneOrderControllerProvider.select((state) => state.customer),
  );
  if (customer == null || customer.key != customerKey) {
    return const CustomerPurchaseHistory.empty();
  }
  return ref.watch(phoneOrdersRepositoryProvider).fetchCustomerHistory(customer);
});

/// The order being taken over the phone: the caller, their cart and the
/// delivery fee. Kept while staff switch between orders on the dashboard.
class PhoneOrderController extends Notifier<PhoneOrderState> {
  @override
  PhoneOrderState build() => const PhoneOrderState();

  /// A new caller starts a new cart.
  void selectCustomer(PhoneOrderCustomer customer) {
    final same = state.customer?.key == customer.key;
    state = state.copyWith(
      customer: customer,
      lines: same ? state.lines : const [],
    );
  }

  /// [selectCustomer], then the delivery fee of the customer's zone (from
  /// `delivery_zones`, matched by its Fujitsu id, else by name) when it has
  /// one. The fee stays editable afterwards.
  Future<void> selectCustomerWithZoneFee(PhoneOrderCustomer customer) async {
    selectCustomer(customer);
    final zoneId = customer.fujitsuZoneId?.trim();
    final zone = customer.zone?.trim();
    final hasId = zoneId != null && zoneId.isNotEmpty;
    if (!hasId && (zone == null || zone.isEmpty)) return;
    try {
      final areas = await ref.read(phoneOrdersRepositoryProvider).fetchAreas();
      final matches = hasId
          ? areas.where((area) => area.fujitsuZoneId == zoneId)
          : areas.where((area) => area.name == zone);
      final fee = matches.map((area) => area.deliveryFee).firstOrNull;
      // The caller may have changed while the zones were loading.
      if (fee != null && state.customer?.key == customer.key) {
        setDeliveryFee(fee);
      }
    } catch (_) {
      // Zones are optional; keep the current fee.
    }
  }

  /// Empties the active order (parked orders stay).
  void clear() => state = PhoneOrderState(
        id: state.id,
        nextId: state.nextId,
        parked: state.parked,
      );

  // ------------------------------------------------------ open orders

  /// Parks the active order (caller, cart, fee, payment and receipt) and
  /// opens a blank one. Nothing to park when the active order is blank.
  void parkAndNew() {
    if (state.isBlank || state.submitting) return;
    final parked = [...state.parked, state.copyWith(parked: const [])];
    state = PhoneOrderState(
      id: state.nextId,
      nextId: state.nextId + 1,
      parked: parked,
    );
  }

  /// Makes the parked order [id] the active one; the order being left is
  /// parked (a blank one is dropped).
  void switchTo(int id) {
    if (id == state.id || state.submitting) return;
    final target = state.parked.where((o) => o.id == id).firstOrNull;
    if (target == null) return;
    final others = [
      for (final order in state.parked)
        if (order.id != id) order,
    ];
    final leaving = state.copyWith(parked: const []);
    state = target.copyWith(
      parked: leaving.isBlank ? others : [...others, leaving],
      nextId: state.nextId,
    );
  }

  /// Throws the active order away (cart, caller, fee and payment). The most
  /// recently parked order, if any, becomes the active one.
  void cancelCurrent() {
    if (state.submitting) return;
    _closeActive();
  }

  void _closeActive() {
    final parked = state.parked;
    if (parked.isEmpty) {
      state = PhoneOrderState(id: state.nextId, nextId: state.nextId + 1);
      return;
    }
    state = parked.last.copyWith(
      parked: parked.sublist(0, parked.length - 1),
      nextId: state.nextId,
    );
  }

  // ------------------------------------------------------------ payment

  /// Switching away from InstaPay drops the receipt image.
  void setPayment(PhoneOrderPayment method) => state = state.copyWith(
        paymentMethod: method,
        clearReceipt: !method.needsReceipt,
      );

  void setReceipt(PaymentReceiptImage? receipt) => state = receipt == null
      ? state.copyWith(clearReceipt: true)
      : state.copyWith(receipt: receipt);

  /// Unit products only. Weight-based products go through [setWeight].
  void add(Product product) {
    if (product.isWeightBased) {
      final grams = state.weightOf(product.id) ?? WeightOptions.defaultGrams;
      setWeight(product, WeightOptions.next(grams));
      return;
    }
    setQuantity(product, state.quantityOf(product.id) + 1);
  }

  /// Adds exactly [quantity] more of a unit product (bulk add).
  void addQuantity(Product product, int quantity) {
    if (quantity < 1) return;
    setQuantity(product, state.quantityOf(product.id) + quantity);
  }

  void remove(Product product) {
    if (product.isWeightBased) {
      final grams = state.weightOf(product.id);
      if (grams == null) return;
      setWeight(product, WeightOptions.previous(grams));
      return;
    }
    setQuantity(product, state.quantityOf(product.id) - 1);
  }

  void setQuantity(Product product, int quantity) {
    final clamped = quantity.clamp(0, PhoneOrderState.maxQuantity);
    final lines = [...state.lines];
    final index = lines.indexWhere((line) => line.product.id == product.id);
    if (clamped == 0) {
      if (index >= 0) lines.removeAt(index);
    } else if (index >= 0) {
      lines[index] = PhoneOrderLine(product: product, quantity: clamped);
    } else {
      lines.add(PhoneOrderLine(product: product, quantity: clamped));
    }
    state = state.copyWith(lines: lines);
  }

  /// Sets or clears a weight-based line. [grams] ≤ 0 removes it.
  void setWeight(Product product, int grams) {
    final lines = [...state.lines];
    final index = lines.indexWhere((line) => line.product.id == product.id);
    if (grams <= 0) {
      if (index >= 0) lines.removeAt(index);
    } else if (index >= 0) {
      lines[index] = PhoneOrderLine(
        product: product,
        quantity: 1,
        weightInGrams: grams,
      );
    } else {
      lines.add(PhoneOrderLine(
        product: product,
        quantity: 1,
        weightInGrams: grams,
      ));
    }
    state = state.copyWith(lines: lines);
  }

  void setDeliveryFee(double fee) =>
      state = state.copyWith(deliveryFee: fee < 0 ? 0 : fee);

  /// Replaces the cart (e.g. «إعادة آخر طلب بالكامل»).
  void replaceLines(List<PhoneOrderLine> lines) =>
      state = state.copyWith(lines: List.of(lines));

  /// Sets the cart line to the caller's last amount for [product].
  void addFromHistory(
    Product product, {
    int? lastQuantity,
    int? lastWeightInGrams,
  }) {
    if (product.isWeightBased ||
        (lastWeightInGrams != null && lastWeightInGrams > 0)) {
      final grams = (lastWeightInGrams != null && lastWeightInGrams > 0)
          ? lastWeightInGrams
          : WeightOptions.defaultGrams;
      setWeight(product, grams);
      return;
    }
    setQuantity(
      product,
      (lastQuantity ?? 1).clamp(1, PhoneOrderState.maxQuantity),
    );
  }

  /// Places the order and starts over; returns the new order's id.
  Future<String> submit() async {
    final customer = state.customer;
    if (customer == null || !state.canSubmit) {
      throw StateError('Nothing to submit');
    }
    state = state.copyWith(submitting: true);
    try {
      final orderId = await ref.read(phoneOrdersRepositoryProvider).placeOrder(
            customer: customer,
            lines: state.lines,
            deliveryFee: state.deliveryFee,
            paymentMethod: state.paymentMethod,
            receipt: state.receipt,
          );
      unawaited(
        ref.read(orderPushDispatcherProvider).notifyOrderCreated(orderId),
      );
      _closeActive();
      return orderId;
    } catch (_) {
      state = state.copyWith(submitting: false);
      rethrow;
    }
  }
}
