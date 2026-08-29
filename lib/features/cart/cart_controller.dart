import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/providers.dart';
import '../../shared/models/cart_item.dart';
import '../../shared/models/product.dart';

/// Why an add-to-cart attempt was rejected.
enum CartAddError { optionRequired, sizeRequired, outOfStock, maxQuantity }

/// Outcome of an add-to-cart attempt.
class CartAddResult {
  const CartAddResult.success()
      : error = null,
        availableQuantity = null;
  const CartAddResult.failure(this.error, {this.availableQuantity});

  final CartAddError? error;
  final int? availableQuantity;

  bool get isSuccess => error == null;
}

/// The shopping cart, persisted between launches.
class CartController extends Notifier<List<CartItem>> {
  static const String storageKey = 'rawnq.cart.v1';

  late final SharedPreferences _prefs;

  @override
  List<CartItem> build() {
    _prefs = ref.watch(sharedPreferencesProvider);
    return _restore();
  }

  /// Adds [product] to the cart, enforcing the option rules the storefront
  /// enforces: a product with variants cannot be bought without choosing one,
  /// and a variant that offers sizes cannot be bought without a size.
  CartAddResult add(
    Product product, {
    ProductVariant? variant,
    int quantity = 1,
  }) {
    if (product.requiresSelection && variant == null) {
      return const CartAddResult.failure(CartAddError.optionRequired);
    }
    if (variant != null && product.hasSizes && (variant.size ?? '').isEmpty) {
      final sizesExist = product.sizesFor(variant.color).isNotEmpty;
      if (sizesExist) {
        return const CartAddResult.failure(CartAddError.sizeRequired);
      }
    }

    final available = variant != null ? variant.stock.floor() : product.stock.floor();
    if (available <= 0) {
      return const CartAddResult.failure(CartAddError.outOfStock);
    }

    final line = CartItem.fromProduct(product, variant: variant, quantity: quantity);
    final existing = _indexOf(line.key);
    final currentQuantity = existing == -1 ? 0 : state[existing].quantity;
    final desired = currentQuantity + quantity;

    if (desired > available) {
      return CartAddResult.failure(CartAddError.maxQuantity, availableQuantity: available);
    }

    final next = List<CartItem>.of(state);
    if (existing == -1) {
      next.add(line);
    } else {
      next[existing] = next[existing].copyWith(quantity: desired);
    }
    _commit(next);
    return const CartAddResult.success();
  }

  /// Sets an exact quantity. A quantity of zero removes the line.
  CartAddResult setQuantity(String key, int quantity) {
    final index = _indexOf(key);
    if (index == -1) return const CartAddResult.success();
    if (quantity <= 0) {
      remove(key);
      return const CartAddResult.success();
    }

    final item = state[index];
    final max = item.maxQuantity;
    if (max != null && quantity > max) {
      return CartAddResult.failure(CartAddError.maxQuantity, availableQuantity: max);
    }

    final next = List<CartItem>.of(state);
    next[index] = item.copyWith(quantity: quantity);
    _commit(next);
    return const CartAddResult.success();
  }

  CartAddResult increment(String key) {
    final index = _indexOf(key);
    if (index == -1) return const CartAddResult.success();
    return setQuantity(key, state[index].quantity + 1);
  }

  void decrement(String key) {
    final index = _indexOf(key);
    if (index == -1) return;
    setQuantity(key, state[index].quantity - 1);
  }

  void remove(String key) {
    _commit(state.where((item) => item.key != key).toList(growable: false));
  }

  /// Puts a removed line back, used by the undo action.
  void restore(CartItem item, {int? at}) {
    final next = List<CartItem>.of(state);
    final index = at == null || at < 0 || at > next.length ? next.length : at;
    next.insert(index, item);
    _commit(next);
  }

  void clear() => _commit(const <CartItem>[]);

  int indexOf(String key) => _indexOf(key);

  int _indexOf(String key) => state.indexWhere((item) => item.key == key);

  void _commit(List<CartItem> next) {
    state = List<CartItem>.unmodifiable(next);
    unawaited(
      _prefs.setString(
        storageKey,
        jsonEncode(next.map((item) => item.toJson()).toList(growable: false)),
      ),
    );
  }

  List<CartItem> _restore() {
    final raw = _prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return const <CartItem>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <CartItem>[];
      return List<CartItem>.unmodifiable(
        decoded.whereType<Map<String, dynamic>>().map(CartItem.fromJson),
      );
    } on FormatException {
      // A corrupt cart should not brick the app; start empty instead.
      return const <CartItem>[];
    }
  }
}

final cartProvider = NotifierProvider<CartController, List<CartItem>>(CartController.new);

/// Sum of the line totals, before delivery.
final cartSubtotalProvider = Provider<double>((ref) {
  final items = ref.watch(cartProvider);
  return items.fold<double>(0, (sum, item) => sum + item.lineTotal);
});

/// Total number of individual pieces in the cart — the badge number.
final cartCountProvider = Provider<int>((ref) {
  final items = ref.watch(cartProvider);
  return items.fold<int>(0, (sum, item) => sum + item.quantity);
});
