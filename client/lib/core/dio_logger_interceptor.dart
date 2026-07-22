import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:l/l.dart';

/// {@template dio_logger_interceptor}
/// Dio interceptor that logs requests and responses via the `l` package.
/// Logs are only emitted in debug mode.
/// {@endtemplate}
base class DioLoggerInterceptor extends Interceptor {
  /// {@macro dio_logger_interceptor}
  const DioLoggerInterceptor({required this.keyName, this.enabled = true});

  /// Keyword label prepended to every log line (e.g. `main`, `base`).
  final String keyName;

  /// Whether logging is active. Should be `false` in release.
  final bool enabled;

  String get _tag => '[dio:$keyName]';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!enabled) return handler.next(options);
    final uri = options.uri;
    final headerSection = _headerSection(options.headers);
    final bodySection = _bodySection(options.data);
    l.i(
      '$_tag REQUEST ${options.method} $uri'
      '$headerSection'
      '$bodySection',
    );
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    if (!enabled) return handler.next(response);
    final request = response.requestOptions;
    final headerSection = _headerSection(response.headers.map);
    final bodySection = _bodySection(response.data);
    l.i(
      '$_tag RESPONSE ${response.statusCode} ${request.method} ${request.uri}'
      '$headerSection'
      '$bodySection',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (!enabled) return handler.next(err);
    final request = err.requestOptions;
    final headerSection = _headerSection(err.response?.headers.map);
    final bodySection = _bodySection(err.response?.data);
    l.e(
      '$_tag ERROR ${err.type.name} ${request.method} ${request.uri}\n'
      'Status: ${err.response?.statusCode}\n'
      'Message: ${err.message}'
      '$headerSection'
      '$bodySection',
      err.stackTrace,
    );
    handler.next(err);
  }

  String _headerSection(Map<String, dynamic>? headers) {
    if (headers == null || headers.isEmpty) return '';
    final encoded = const JsonEncoder.withIndent('  ').convert(headers);
    return '\nHeaders:\n$encoded';
  }

  String _bodySection(Object? body) {
    final encoded = _encodeBody(body);
    if (encoded.isEmpty) return '';
    return '\nBody:\n$encoded';
  }

  String _encodeBody(Object? body) {
    if (body == null) return '';
    if (body is String) return body.isEmpty ? '' : body;
    if (body is Map || body is List) {
      if (body is Map && body.isEmpty) return '';
      if (body is List && body.isEmpty) return '';
      return const JsonEncoder.withIndent('  ').convert(body);
    }
    return body.toString();
  }
}
