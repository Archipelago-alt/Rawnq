import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rawnq/core/config/app_config.dart';
import 'package:rawnq/core/network/api_client.dart';
import 'package:rawnq/core/utils/result.dart';
import 'package:rawnq/shared/data/local_catalog_repository.dart';
import 'package:rawnq/shared/data/remote_catalog_repository.dart';

/// Serves canned JSON in place of the network, so no test ever depends on the
/// live storefront being reachable.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);

  final Object? Function(RequestOptions options) handler;
  final List<String> requestedPaths = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestedPaths.add('${options.path}?${options.uri.query}');
    final result = handler(options);
    if (result is DioException) throw result;
    if (result is int) {
      return ResponseBody.fromString('{"message":"error"}', result);
    }
    return ResponseBody.fromString(
      jsonEncode(result),
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// An asset bundle backed by an in-memory string.
class _FakeBundle extends CachingAssetBundle {
  _FakeBundle(this.contents);

  final Map<String, String> contents;

  @override
  Future<ByteData> load(String key) async {
    final value = contents[key];
    if (value == null) throw FlutterError('asset not found: $key');
    final bytes = utf8.encode(value);
    return ByteData.view(Uint8List.fromList(bytes).buffer);
  }
}

const _config = AppConfig(
  supabaseUrl: 'https://example.supabase.co',
  supabaseAnonKey: 'test-key',
  tenantSlug: 'rawnqgaza',
);

Map<String, dynamic> _tenantRow() => <String, dynamic>{
  'id': 'tenant-1',
  'slug': 'rawnqgaza',
  'store_label': 'رونق | RAWNQ',
  'store_slogan_ar': 'لأنكِ تستحقين الأجمل',
  'brand_color': '#7c3918',
  'currency': 'ILS',
  'store_whatsapp': '+970593208117',
  'show_stock_to_mobile': false,
  'social_links': <String, dynamic>{
    'instagram': 'https://instagram.com/rawnqgaza',
  },
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppConfig', () {
    test('reports no remote API when the key is missing', () {
      const config = AppConfig(
        supabaseUrl: 'https://example.supabase.co',
        supabaseAnonKey: '',
        tenantSlug: 'rawnqgaza',
      );

      expect(config.hasRemoteApi, isFalse);
    });

    test('rejects a non-https URL', () {
      const config = AppConfig(
        supabaseUrl: 'http://example.supabase.co',
        supabaseAnonKey: 'k',
        tenantSlug: 'rawnqgaza',
      );

      expect(config.hasRemoteApi, isFalse);
    });

    test('builds the REST base URL without a duplicate slash', () {
      const config = AppConfig(
        supabaseUrl: 'https://example.supabase.co/',
        supabaseAnonKey: 'k',
        tenantSlug: 'rawnqgaza',
      );

      expect(config.restBaseUrl, 'https://example.supabase.co/rest/v1');
      expect(config.hasRemoteApi, isTrue);
    });
  });

  group('LocalCatalogRepository', () {
    test('parses the bundled snapshot', () async {
      final bundle = _FakeBundle(<String, String>{
        LocalCatalogRepository.assetPath: jsonEncode(<String, dynamic>{
          'capturedAt': '2026-08-29T12:00:00Z',
          'store': <String, dynamic>{
            'id': 't',
            'slug': 'rawnqgaza',
            'label': 'رونق | RAWNQ',
            'brandColor': '#7c3918',
            'currency': 'ILS',
            'whatsapp': '+970593208117',
          },
          'categories': <dynamic>[
            <String, dynamic>{'id': 'c1', 'name': 'بجامات', 'sortOrder': 3},
          ],
          'brands': <dynamic>[
            <String, dynamic>{'id': 'b1', 'name': 'لبنى'},
          ],
          'products': <dynamic>[
            <String, dynamic>{
              'id': 'p1',
              'name': 'بجامة',
              'price': 100,
              'categoryId': 'c1',
              'images': <String>['https://cdn/a.webp'],
              'variants': <dynamic>[
                <String, dynamic>{
                  'id': 'v1',
                  'productId': 'p1',
                  'name': 'اسود-لارج',
                  'price': 100,
                  'stock': 2,
                  'color': 'اسود',
                  'colorHex': '#11121A',
                  'size': 'L',
                },
              ],
            },
          ],
          'deliveryLocations': <dynamic>[
            <String, dynamic>{'id': 'd1', 'name': 'غزة', 'price': 0},
          ],
          'paymentMethods': <dynamic>[
            <String, dynamic>{
              'id': 'm1',
              'name': 'الدفع عند الاستلام',
              'type': 'cod',
            },
          ],
        }),
      });

      final catalog = await LocalCatalogRepository(bundle: bundle)
          .loadCatalog();

      expect(
        catalog.isLiveData,
        isFalse,
        reason: 'snapshot data is never live',
      );
      expect(catalog.capturedAt, DateTime.utc(2026, 8, 29, 12));
      expect(catalog.store.label, 'رونق | RAWNQ');
      expect(catalog.store.whatsappDigits, '970593208117');
      expect(catalog.categories.single.name, 'بجامات');
      expect(catalog.products.single.variants.single.size, 'L');
      expect(catalog.deliveryLocations.single.isFree, isTrue);
      expect(catalog.paymentMethods.single.isCashOnDelivery, isTrue);
    });

    test('the parsed snapshot is cached between calls', () async {
      var loads = 0;
      final bundle = _CountingBundle(() {
        loads++;
        return jsonEncode(<String, dynamic>{
          'store': <String, dynamic>{
            'id': 't',
            'slug': 's',
            'label': 'x',
            'currency': 'ILS',
          },
          'categories': <dynamic>[],
          'brands': <dynamic>[],
          'products': <dynamic>[],
          'deliveryLocations': <dynamic>[],
          'paymentMethods': <dynamic>[],
        });
      });
      final repository = LocalCatalogRepository(bundle: bundle);

      await repository.loadCatalog();
      await repository.loadCatalog();

      expect(loads, 1);
    });
  });

  group('RemoteCatalogRepository', () {
    test('maps the live schema, including tier-1 pricing', () async {
      final adapter = _FakeAdapter((options) {
        if (options.path.endsWith('/tenants')) return <dynamic>[_tenantRow()];
        if (options.path.endsWith('/categories')) {
          return <dynamic>[
            <String, dynamic>{'id': 'c1', 'name': 'بجامات', 'sort_order': 3},
          ];
        }
        if (options.path.endsWith('/brands')) {
          return <dynamic>[
            <String, dynamic>{'id': 'b1', 'name': 'لبنى'},
          ];
        }
        if (options.path.endsWith('/products')) {
          return <dynamic>[
            <String, dynamic>{
              'id': 'p1',
              'name': 'بجامة منزلية',
              // The live API keeps `price` at 0 and the real price in price_1.
              'price': 0,
              'price_1': 100,
              'category_id': 'c1',
              'brand_id': 'b1',
              'labels': <String>['new'],
              'image_url_1': 'https://cdn/a.webp',
            },
          ];
        }
        if (options.path.endsWith('/product_variants')) {
          return <dynamic>[
            <String, dynamic>{
              'id': 'v1',
              'product_id': 'p1',
              'variant_name': 'اسود-لارج',
              'price_1': 100,
              'stock_quantity': 2,
              'attributes': <String, dynamic>{
                'color': 'اسود',
                'color_hex': '#11121A',
                'size': 'L',
              },
            },
          ];
        }
        if (options.path.endsWith('/delivery_locations')) {
          return <dynamic>[
            <String, dynamic>{'id': 'd1', 'name': 'غزة', 'delivery_price': 0},
          ];
        }
        if (options.path.endsWith('/payment_methods')) {
          return <dynamic>[
            <String, dynamic>{
              'id': 'm1',
              'method_name_ar': 'الدفع عند الاستلام',
              'method_type': 'cod',
            },
          ];
        }
        return <dynamic>[];
      });

      final dio = Dio()..httpClientAdapter = adapter;
      final catalog = await RemoteCatalogRepository(
        client: ApiClient(config: _config, dio: dio),
      ).loadCatalog();

      expect(catalog.isLiveData, isTrue);
      expect(
        catalog.products.single.price,
        100,
        reason: 'price_1 must be normalised into price',
      );
      expect(catalog.products.single.isNew, isTrue);
      expect(catalog.products.single.images, <String>['https://cdn/a.webp']);
      expect(catalog.products.single.variants.single.color, 'اسود');
      expect(catalog.store.slogan, 'لأنكِ تستحقين الأجمل');

      // Every catalogue request must be scoped to the tenant.
      final scoped = adapter.requestedPaths
          .where((path) => !path.contains('/tenants'))
          .toList();
      expect(scoped, isNotEmpty);
      expect(
        scoped.every((path) => path.contains('tenant_id=eq.tenant-1')),
        isTrue,
      );
    });

    test('a connection error surfaces as an offline failure', () async {
      final adapter = _FakeAdapter(
        (options) => DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        ),
      );
      final dio = Dio()..httpClientAdapter = adapter;

      await expectLater(
        RemoteCatalogRepository(
          client: ApiClient(config: _config, dio: dio),
        ).loadCatalog(),
        throwsA(
          isA<Failure>().having((f) => f.kind, 'kind', FailureKind.offline),
        ),
      );
    });

    test('a timeout surfaces as a timeout failure', () async {
      final adapter = _FakeAdapter(
        (options) => DioException(
          requestOptions: options,
          type: DioExceptionType.receiveTimeout,
        ),
      );
      final dio = Dio()..httpClientAdapter = adapter;

      await expectLater(
        RemoteCatalogRepository(
          client: ApiClient(config: _config, dio: dio),
        ).loadCatalog(),
        throwsA(
          isA<Failure>().having((f) => f.kind, 'kind', FailureKind.timeout),
        ),
      );
    });

    test('a 5xx surfaces as a server failure', () async {
      final adapter = _FakeAdapter((options) => 500);
      final dio = Dio()..httpClientAdapter = adapter;

      await expectLater(
        RemoteCatalogRepository(
          client: ApiClient(config: _config, dio: dio),
        ).loadCatalog(),
        throwsA(
          isA<Failure>().having((f) => f.kind, 'kind', FailureKind.server),
        ),
      );
    });

    test('an unknown tenant surfaces as not-found', () async {
      final adapter = _FakeAdapter((options) => <dynamic>[]);
      final dio = Dio()..httpClientAdapter = adapter;

      await expectLater(
        RemoteCatalogRepository(
          client: ApiClient(config: _config, dio: dio),
        ).loadCatalog(),
        throwsA(
          isA<Failure>().having((f) => f.kind, 'kind', FailureKind.notFound),
        ),
      );
    });

    test('a failure after the tenant loads propagates without unhandled errors', () async {
      // Every catalogue request fails at once. Future.wait surfaces the first;
      // the rest must not escape as unhandled async errors.
      final adapter = _FakeAdapter((options) {
        if (options.path.endsWith('/tenants')) return <dynamic>[_tenantRow()];
        return DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        );
      });
      final dio = Dio()..httpClientAdapter = adapter;

      await expectLater(
        RemoteCatalogRepository(
          client: ApiClient(config: _config, dio: dio),
        ).loadCatalog(),
        throwsA(
          isA<Failure>().having((f) => f.kind, 'kind', FailureKind.offline),
        ),
      );

      // Give any stray error a turn to surface before the test ends.
      await Future<void>.delayed(Duration.zero);
    });

    test(
      'results are cached until the TTL expires, and forceRefresh bypasses it',
      () async {
        var tenantCalls = 0;
        final adapter = _FakeAdapter((options) {
          if (options.path.endsWith('/tenants')) {
            tenantCalls++;
            return <dynamic>[_tenantRow()];
          }
          return <dynamic>[];
        });
        final dio = Dio()..httpClientAdapter = adapter;
        final repository = RemoteCatalogRepository(
          client: ApiClient(config: _config, dio: dio),
          cacheTtl: const Duration(minutes: 10),
        );

        await repository.loadCatalog();
        await repository.loadCatalog();
        expect(tenantCalls, 1);

        await repository.loadCatalog(forceRefresh: true);
        expect(tenantCalls, 2);
      },
    );
  });
}

/// Deliberately does not cache, so the test measures the repository's own
/// caching rather than the bundle's.
class _CountingBundle extends CachingAssetBundle {
  _CountingBundle(this.builder);

  final String Function() builder;

  @override
  Future<String> loadString(String key, {bool cache = true}) async => builder();

  @override
  Future<ByteData> load(String key) async {
    final bytes = utf8.encode(builder());
    return ByteData.view(Uint8List.fromList(bytes).buffer);
  }
}
