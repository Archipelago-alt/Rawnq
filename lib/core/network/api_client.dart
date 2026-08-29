import 'dart:async';

import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../utils/result.dart';

/// Thin wrapper over the storefront's PostgREST API.
///
/// Deliberately read-only: the app never writes to the platform's database.
/// See `docs/api-integration.md` for why.
class ApiClient {
  ApiClient({required AppConfig config, Dio? dio})
      : _config = config,
        _dio = dio ?? Dio() {
    _dio.options = _dio.options.copyWith(
      baseUrl: config.restBaseUrl,
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 12),
      responseType: ResponseType.json,
      headers: <String, String>{
        'apikey': config.supabaseAnonKey,
        'Authorization': 'Bearer ${config.supabaseAnonKey}',
        'Accept': 'application/json',
      },
    );
  }

  final AppConfig _config;
  final Dio _dio;

  static const int pageSize = 500;

  /// Fetches every row of [table] matching [query], following PostgREST's
  /// range pagination until a short page comes back.
  Future<List<Map<String, dynamic>>> selectAll(
    String table, {
    required Map<String, String> query,
  }) async {
    final rows = <Map<String, dynamic>>[];
    var offset = 0;
    while (true) {
      final page = await select(
        table,
        query: <String, String>{
          ...query,
          'offset': '$offset',
          'limit': '$pageSize',
        },
      );
      rows.addAll(page);
      if (page.length < pageSize) break;
      offset += pageSize;
    }
    return rows;
  }

  Future<List<Map<String, dynamic>>> select(
    String table, {
    required Map<String, String> query,
  }) async {
    try {
      final response = await _dio.get<dynamic>('/$table', queryParameters: query);
      final data = response.data;
      if (data is! List) {
        throw const Failure(FailureKind.server, detail: 'unexpected payload shape');
      }
      return data.whereType<Map<String, dynamic>>().toList(growable: false);
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  /// Tenant filter shared by every storefront query.
  Map<String, String> tenantFilter(String tenantId) =>
      <String, String>{'tenant_id': 'eq.$tenantId'};

  String get tenantSlug => _config.tenantSlug;

  Failure _mapError(DioException error) {
    // The detail is a coarse label only — request URLs and payloads are not
    // logged, so customer data never reaches a log sink.
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const Failure(FailureKind.timeout);
      case DioExceptionType.connectionError:
        return const Failure(FailureKind.offline);
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode ?? 0;
        if (status == 404) return const Failure(FailureKind.notFound);
        return Failure(FailureKind.server, detail: 'http $status');
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return const Failure(FailureKind.unknown);
    }
  }
}
