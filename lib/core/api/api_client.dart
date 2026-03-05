import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../storage/secure_storage.dart';

class ApiClient {
  ApiClient._internal();

  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  final SecureStorage _storage = SecureStorage();

  late final Dio dio = Dio(
    BaseOptions(
      baseUrl: _resolveBaseUrl(),
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: const {'Content-Type': 'application/json'},
    ),
  )..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );

  static String _resolveBaseUrl() {
    const fromDefine = String.fromEnvironment('API_BASE_URL');
    if (fromDefine.isNotEmpty) {
      return fromDefine;
    }

    if (kIsWeb) {
      return 'http://localhost:3000/api/v1';
    }

    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000/api/v1';
    }

    if (Platform.isIOS || Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      return 'http://localhost:3000/api/v1';
    }

    return 'http://localhost:3000/api/v1';
  }
}
