import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front/core/providers/storage_providers.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: 'http://192.168.1.101:3000/api', // Replace with your backend URL
  ));

  final tokenStorageService = ref.watch(tokenStorageServiceProvider);

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await tokenStorageService.getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await tokenStorageService.deleteToken();
        }
        return handler.next(error);
      },
    ),
  );

  return dio;
});
