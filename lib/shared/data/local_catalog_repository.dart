import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/catalog.dart';
import 'catalog_repository.dart';

/// Reads the catalogue snapshot shipped inside the app bundle.
///
/// This is local development data — a point-in-time copy of the publicly
/// readable storefront taken on 2026-08-29. It is real content, but it is not
/// live, and the UI labels it as such.
class LocalCatalogRepository implements CatalogRepository {
  LocalCatalogRepository({AssetBundle? bundle}) : _bundle = bundle;

  static const String assetPath = 'assets/data/catalog_snapshot.json';

  final AssetBundle? _bundle;
  Catalog? _cached;

  @override
  Future<Catalog> loadCatalog({bool forceRefresh = false}) async {
    final cached = _cached;
    if (cached != null && !forceRefresh) return cached;

    final raw = await (_bundle ?? rootBundle).loadString(assetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final catalog = Catalog.fromSnapshot(json);
    _cached = catalog;
    return catalog;
  }
}
