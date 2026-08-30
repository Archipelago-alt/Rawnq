import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/providers.dart';

/// Favourite product ids, persisted between launches.
class FavoritesController extends Notifier<Set<String>> {
  static const String storageKey = 'rawnq.favorites.v1';

  // Not `late final`: Riverpod rebuilds a Notifier when a watched provider
  // changes, and a second assignment to a late final field would throw.
  late SharedPreferences _prefs;

  @override
  Set<String> build() {
    _prefs = ref.watch(sharedPreferencesProvider);
    final stored = _prefs.getStringList(storageKey) ?? const <String>[];
    return Set<String>.unmodifiable(stored);
  }

  bool isFavorite(String productId) => state.contains(productId);

  /// Returns true when the product ended up favourited.
  bool toggle(String productId) {
    final next = Set<String>.of(state);
    final added = next.add(productId);
    if (!added) next.remove(productId);
    state = Set<String>.unmodifiable(next);
    _persist(next);
    return added;
  }

  void clear() {
    state = const <String>{};
    unawaited(_prefs.remove(storageKey));
  }

  // Persistence failures must not break the interaction: the in-memory state
  // is already updated and is rewritten on the next toggle.
  void _persist(Set<String> value) {
    unawaited(_prefs.setStringList(storageKey, value.toList(growable: false)));
  }
}

final favoritesProvider = NotifierProvider<FavoritesController, Set<String>>(
  FavoritesController.new,
);

/// Whether a single product is favourited — cheap to watch per card.
final isFavoriteProvider = Provider.family<bool, String>(
  (ref, id) => ref.watch(favoritesProvider).contains(id),
);
