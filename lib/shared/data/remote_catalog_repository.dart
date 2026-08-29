import '../../core/network/api_client.dart';
import '../../core/utils/result.dart';
import '../models/catalog.dart';
import '../models/category.dart';
import '../models/checkout_options.dart';
import '../models/product.dart';
import '../models/store_info.dart';
import 'catalog_repository.dart';

/// Reads the live storefront over its public, read-only REST API.
///
/// Endpoint and column choices are documented in `docs/api-integration.md`.
class RemoteCatalogRepository implements CatalogRepository {
  RemoteCatalogRepository({
    required ApiClient client,
    Duration cacheTtl = const Duration(minutes: 10),
  })  : _client = client,
        _cacheTtl = cacheTtl;

  final ApiClient _client;
  final Duration _cacheTtl;

  Catalog? _cached;
  DateTime? _cachedAt;

  @override
  Future<Catalog> loadCatalog({bool forceRefresh = false}) async {
    final cached = _cached;
    final cachedAt = _cachedAt;
    final isFresh = cached != null &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < _cacheTtl;
    if (isFresh && !forceRefresh) return cached;

    final store = await _loadStore();
    final tenant = _client.tenantFilter(store.id);

    // Independent requests, so run them together rather than in sequence.
    final results = await Future.wait(<Future<List<Map<String, dynamic>>>>[
      _client.selectAll('categories', query: <String, String>{
        ...tenant,
        'select': '*',
        'is_active': 'eq.true',
        'order': 'sort_order.asc',
      }),
      _client.selectAll('brands', query: <String, String>{
        ...tenant,
        'select': '*',
        'is_active': 'eq.true',
        'order': 'sort_order.asc',
      }),
      _client.selectAll('products', query: <String, String>{
        ...tenant,
        'select': '*',
        'is_active': 'eq.true',
        'order': 'sort_order.asc',
      }),
      _client.selectAll('product_variants', query: <String, String>{
        ...tenant,
        'select': '*',
        'is_active': 'eq.true',
        'order': 'sort_order.asc',
      }),
      _client.selectAll('delivery_locations', query: <String, String>{
        ...tenant,
        'select': '*',
        'is_active': 'eq.true',
      }),
      _client.selectAll('payment_methods', query: <String, String>{
        ...tenant,
        'select': '*',
        'is_active': 'eq.true',
      }),
    ]);

    final variantsByProduct = <String, List<ProductVariant>>{};
    for (final row in results[3]) {
      final variant = ProductVariant.fromJson(row);
      if (variant.productId.isEmpty) continue;
      variantsByProduct.putIfAbsent(variant.productId, () => <ProductVariant>[]).add(variant);
    }

    final products = results[2]
        .map((row) => Product.fromJson(
              _normaliseProduct(row),
              variants: variantsByProduct[row['id']] ?? const <ProductVariant>[],
            ))
        .toList(growable: false);

    final catalog = Catalog(
      store: store,
      categories: results[0].map(ProductCategory.fromJson).toList(growable: false),
      brands: results[1].map(Brand.fromJson).toList(growable: false),
      products: products,
      deliveryLocations: results[4].map(DeliveryLocation.fromJson).toList(growable: false),
      paymentMethods: results[5].map(StorePaymentMethod.fromJson).toList(growable: false),
      isLiveData: true,
    );

    _cached = catalog;
    _cachedAt = DateTime.now();
    return catalog;
  }

  Future<StoreInfo> _loadStore() async {
    final rows = await _client.select('tenants', query: <String, String>{
      'select': '*',
      'slug': 'eq.${_client.tenantSlug}',
      'limit': '1',
    });
    if (rows.isEmpty) throw const Failure(FailureKind.notFound, detail: 'tenant');
    return StoreInfo.fromJson(rows.first);
  }

  /// The platform keeps `price` at 0 and the real retail price in `price_1`.
  /// Normalise here so the model never has to know about pricing tiers.
  Map<String, dynamic> _normaliseProduct(Map<String, dynamic> row) {
    final price = row['price'];
    final tierPrice = row['price_1'];
    if ((price is num && price > 0) || tierPrice is! num) return row;
    return <String, dynamic>{...row, 'price': tierPrice};
  }
}
