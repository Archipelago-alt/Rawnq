import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/app_config.dart';
import '../core/network/api_client.dart';
import '../shared/data/catalog_repository.dart';
import '../shared/data/local_catalog_repository.dart';
import '../shared/data/remote_catalog_repository.dart';
import '../shared/models/catalog.dart';
import '../shared/models/product.dart';

/// Build-time configuration. Overridden in tests.
final appConfigProvider = Provider<AppConfig>(
  (ref) => AppConfig.fromEnvironment(),
);

/// Populated once at startup in `main()` so the rest of the app can read
/// preferences synchronously.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) =>
      throw UnimplementedError('sharedPreferencesProvider must be overridden'),
);

/// Picks the live API when it is configured, and the bundled snapshot
/// otherwise. Nothing downstream needs to know which one it got.
final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  if (!config.hasRemoteApi) return LocalCatalogRepository();
  return RemoteCatalogRepository(client: ApiClient(config: config));
});

/// The whole storefront. Every screen reads from this one future.
final catalogProvider = FutureProvider<Catalog>((ref) async {
  final repository = ref.watch(catalogRepositoryProvider);
  return repository.loadCatalog();
});

/// Pull-to-refresh entry point, called from widgets.
Future<void> refreshCatalog(WidgetRef ref) async {
  final repository = ref.read(catalogRepositoryProvider);
  await repository.loadCatalog(forceRefresh: true);
  ref.invalidate(catalogProvider);
  await ref.read(catalogProvider.future);
}

/// Synchronous access to the loaded catalogue, or null while it loads.
final loadedCatalogProvider = Provider<Catalog?>(
  (ref) => ref.watch(catalogProvider).asData?.value,
);

/// Looks up one product by id from the loaded catalogue.
final productByIdProvider = Provider.family<Product?, String>(
  (ref, id) => ref.watch(loadedCatalogProvider)?.productById(id),
);
