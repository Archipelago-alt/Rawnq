import '../models/catalog.dart';

/// The app's single source of catalogue data.
///
/// Two implementations exist — one against the live storefront API, one
/// against the catalogue snapshot bundled with the app — and the rest of the
/// app cannot tell them apart beyond [Catalog.isLiveData].
abstract class CatalogRepository {
  /// Loads the full storefront. Implementations must complete or throw a
  /// [Failure]; they must never hang.
  Future<Catalog> loadCatalog({bool forceRefresh = false});
}
