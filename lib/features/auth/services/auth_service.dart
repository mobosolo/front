import 'package:dio/dio.dart';

class AuthService {
  final Dio _dio;

  AuthService(this._dio);

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      return response.data;
    } on DioException catch (e) {
      // Handle error
      print('DioError: ${e.response?.data}');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> register(String name, String email, String password, String phone, String role) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'displayName': name,
        'email': email,
        'password': password,
        'role': role,
        if (phone.trim().isNotEmpty) 'phoneNumber': phone.trim(),
      });
      return response.data;
    } on DioException catch (e) {
      print('DioError: ${e.response?.data}');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getMe() async {
    try {
      final response = await _dio.get('/auth/me');
      return response.data;
    } on DioException catch (e) {
      print('DioError: ${e.response?.data}');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    String? displayName,
    String? phoneNumber,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (displayName != null) payload['displayName'] = displayName;
      if (phoneNumber != null) payload['phoneNumber'] = phoneNumber;
      if (latitude != null) payload['latitude'] = latitude;
      if (longitude != null) payload['longitude'] = longitude;

      final response = await _dio.put('/auth/profile', data: payload);
      return response.data;
    } on DioException catch (e) {
      print('DioError updating profile: ${e.response?.data}');
      rethrow;
    }
  }

  Future<void> sendFCMToken(String fcmToken) async {
    try {
      await _dio.post('/auth/fcm-token', data: {
        'fcmToken': fcmToken,
      });
    } on DioException catch (e) {
      print('DioError sending FCM token: ${e.response?.data}');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    try {
      final response = await _dio.post('/auth/forgot-password', data: {
        'email': email,
      });
      return response.data;
    } on DioException catch (e) {
      print('DioError requesting password reset: ${e.response?.data}');
      rethrow;
    }
  }

  Future<void> resetPassword(String email, String token, String newPassword) async {
    try {
      await _dio.post('/auth/reset-password', data: {
        'email': email,
        'token': token,
        'newPassword': newPassword,
      });
    } on DioException catch (e) {
      print('DioError resetting password: ${e.response?.data}');
      rethrow;
    }
  }
}
