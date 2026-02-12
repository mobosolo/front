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
        'phoneNumber': phone,
        'role': role,
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

  Future<Map<String, dynamic>> updateProfile({String? displayName, String? phoneNumber}) async {
    try {
      final response = await _dio.put('/auth/profile', data: {
        'displayName': displayName,
        'phoneNumber': phoneNumber,
      });
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
}
