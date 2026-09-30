import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Base URL of the Safety API.
///
/// Override at build time so the same binary can point at a real device
/// server instead of only working behind `adb reverse`:
///
/// ```
/// flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8000/api
/// ```
///
/// The 127.0.0.1 default is correct for the Android emulator and for a device
/// with `adb reverse tcp:8000 tcp:8000` in place.
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8000/api',
);

const String _tokenKey = 'auth_token';

/// Broadcasts when the server rejects the stored token so the app can drop the
/// session instead of silently failing every subsequent request.
///
/// A stream is used rather than a [StateProvider] so the API layer does not
/// need a `Ref`, which would make it depend on the auth provider that already
/// depends on it.
final StreamController<void> sessionExpiredController =
    StreamController<void>.broadcast();

final apiServiceProvider = Provider<ApiService>((ref) {
  final service = ApiService();
  ref.onDispose(service.dispose);
  return service;
});

/// Extracts a human-readable message from a failed request.
///
/// The response body is only inspected when it really is a Map. A
/// misconfigured or crash-looping server answers with an HTML page, and
/// indexing that as a Map throws from inside the caller's `catch` block,
/// which hides the original failure.
///
/// [connectionMessage] is used for timeouts and unreachable hosts, where the
/// server never produced a body worth showing.
String describeApiError(Object error, {String? connectionMessage}) {
  if (error is! DioException) return error.toString();

  if (error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.receiveTimeout ||
      error.type == DioExceptionType.sendTimeout ||
      error.type == DioExceptionType.connectionError) {
    return connectionMessage ?? 'Network unreachable';
  }

  final body = error.response?.data;
  if (body is Map) {
    final errors = body['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final first = errors.values.first;
      if (first is List && first.isNotEmpty) return first.first.toString();
    }

    final message = body['message'];
    if (message is String && message.isNotEmpty) return message;
  }

  final message = error.message;
  if (message != null && message.isNotEmpty) return message;

  return 'HTTP ${error.response?.statusCode ?? '??'}';
}

class ApiService {
  ApiService({Dio? dio, FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage(),
      _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: apiBaseUrl,
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 30),
              // Content-Type is deliberately left to Dio: it derives
              // multipart/form-data plus the boundary for FormData bodies
              // and application/json for maps.
              headers: {'Accept': 'application/json'},
            ),
          ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: _tokenKey);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          // The stored token is gone, expired or was revoked server-side (for
          // example by a password reset). Previously this branch was an empty
          // stub, so the app stayed "logged in" while every request failed.
          final status = e.response?.statusCode;
          final isAuthRoute =
              e.requestOptions.path.contains('/login') ||
              e.requestOptions.path.contains('/register');

          if (status == 401 && !isAuthRoute) {
            unawaited(_handleExpiredSession());
          }

          return handler.next(e);
        },
      ),
    );
  }

  final Dio _dio;
  final FlutterSecureStorage _storage;

  /// Guards against firing the expiry callback once per in-flight request.
  bool _handlingExpiry = false;

  Future<void> _handleExpiredSession() async {
    if (_handlingExpiry) return;
    _handlingExpiry = true;

    try {
      await deleteToken();
      if (!sessionExpiredController.isClosed) {
        sessionExpiredController.add(null);
      }
    } catch (e) {
      debugPrint('Could not clear the expired session: $e');
    } finally {
      _handlingExpiry = false;
    }
  }

  Future<Response<dynamic>> post(String path, {Object? data}) {
    return _dio.post<dynamic>(path, data: data);
  }

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.get<dynamic>(path, queryParameters: queryParameters);
  }

  Future<Response<dynamic>> put(String path, {Object? data}) {
    return _dio.put<dynamic>(path, data: data);
  }

  Future<String?> getToken() => _storage.read(key: _tokenKey);

  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<void> deleteToken() => _storage.delete(key: _tokenKey);

  void dispose() {
    _dio.close(force: true);
  }
}
