import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/providers/settings_providers.dart';
import '../../../home/data/models/product_model.dart';
import '../../../home/domain/entities/product.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/weight_options.dart';

const _cartPrefsKey = 'cart.items';

final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(
  CartNotifier.new,
);

final cartItemCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).fold(0, (sum, item) => sum + item.quantity);
});

final cartTotalProvider = Provider<double>((ref) {
  return ref.watch(cartProvider).fold(0, (sum, item) => sum + item.total);
});

class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() {
    // Persist on every mutation (add / update / remove / clear).
    listenSelf((_, next) => _persist(next));
    return _load();
  }

  SharedPreferences? get _prefs => ref.read(sharedPreferencesProvider);

  List<CartItem> _load() {
    final raw = _prefs?.getString(_cartPrefsKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [
        for (final item in decoded)
          if (item is Map)
            if (_cartItemFromJson(Map<String, dynamic>.from(item))
                case final cartItem?)
              cartItem,
      ];
    } catch (e, st) {
      debugPrint('Failed to restore cart: $e\n$st');
      return const [];
    }
  }

  Future<void> _persist(List<CartItem> items) async {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      await prefs.setString(
        _cartPrefsKey,
        jsonEncode([for (final item in items) _cartItemToJson(item)]),
      );
    } catch (e, st) {
      debugPrint('Failed to persist cart: $e\n$st');
    }
  }

  /// Weight-based products step up to the next weight instead of adding a
  /// whole kilo; prefer [setWeight] with the weight the user picked.
  void add(Product product) {
    final existing = state.where((item) => item.product.id == product.id);
    if (product.isWeightBased) {
      final grams = existing.firstOrNull?.selectedWeightInGrams;
      setWeight(
        product,
        grams == null ? WeightOptions.defaultGrams : WeightOptions.next(grams),
      );
    } else if (existing.isEmpty) {
      state = [...state, CartItem(product: product, quantity: 1)];
    } else {
      updateQuantity(product.id, existing.first.quantity + 1);
    }
  }

  void remove(String productId) {
    state = [
      for (final item in state)
        if (item.product.id != productId) item,
    ];
  }

  /// A quantity of zero or less removes the item.
  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      remove(productId);
      return;
    }
    state = [
      for (final item in state)
        item.product.id == productId ? item.copyWith(quantity: quantity) : item,
    ];
  }

  /// Adds or replaces a weight-based item; zero grams or less removes it.
  void setWeight(Product product, int grams, {String? notes}) {
    if (grams <= 0) {
      remove(product.id);
      return;
    }
    String? existingNotes;
    for (final existing in state) {
      if (existing.product.id == product.id) {
        existingNotes = existing.notes;
        break;
      }
    }
    final item = CartItem(
      product: product,
      quantity: 1,
      selectedWeightInGrams: grams,
      notes: notes ?? existingNotes,
    );
    final exists = state.any((existing) => existing.product.id == product.id);
    state = exists
        ? [
            for (final existing in state)
              existing.product.id == product.id ? item : existing,
          ]
        : [...state, item];
  }

  void setItemNotes(String productId, String? notes) {
    final trimmed = notes?.trim();
    state = [
      for (final item in state)
        item.product.id == productId
            ? item.copyWith(
                notes: trimmed,
                clearNotes: trimmed == null || trimmed.isEmpty,
              )
            : item,
    ];
  }

  void clear() => state = const [];
}

Map<String, dynamic> _cartItemToJson(CartItem item) => {
      'product': ProductModel.toJson(item.product),
      'quantity': item.quantity,
      'selected_weight_in_grams': item.selectedWeightInGrams,
      if (item.trimmedNotes != null) 'notes': item.trimmedNotes,
    };

CartItem? _cartItemFromJson(Map<String, dynamic> json) {
  final productRaw = json['product'];
  if (productRaw is! Map) return null;
  final product = ProductModel.fromJson(Map<String, dynamic>.from(productRaw));
  if (product.id.isEmpty) return null;
  final quantity = switch (json['quantity']) {
    final int value => value,
    final num value => value.round(),
    final String value => int.tryParse(value.trim()),
    _ => null,
  };
  if (quantity == null || quantity <= 0) return null;
  final grams = switch (json['selected_weight_in_grams']) {
    final int value => value,
    final num value => value.round(),
    final String value => int.tryParse(value.trim()),
    _ => null,
  };
  final notesRaw = json['notes']?.toString().trim();
  return CartItem(
    product: product,
    quantity: product.isWeightBased ? 1 : quantity,
    selectedWeightInGrams: product.isWeightBased
        ? (grams == null || grams <= 0 ? WeightOptions.defaultGrams : grams)
        : grams,
    notes: (notesRaw == null || notesRaw.isEmpty) ? null : notesRaw,
  );
}
