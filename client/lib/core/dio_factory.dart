import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:test_task_cards/core/dio_logger_interceptor.dart';

/// {@template dio_factory}
/// Factory that creates pre-configured [Dio] instances with a logging
/// interceptor attached. Logs are only active in debug mode.
/// {@endtemplate}
final class DioFactory {
  const DioFactory._();

  /// Creates a [Dio] instance with [baseUrl] and a [DioLoggerInterceptor]
  /// tagged with [keyName].
  static Dio create({required String baseUrl, required String keyName}) {
    final dio = Dio(BaseOptions(baseUrl: baseUrl));
    dio.interceptors.add(DioLoggerInterceptor(keyName: keyName, enabled: kDebugMode));
    return dio;
  }
}
