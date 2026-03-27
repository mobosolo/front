import 'package:dio/dio.dart';
import 'package:front/features/notifications/models/app_notification_model.dart';

class AppNotificationService {
  final Dio _dio;

  AppNotificationService(this._dio);

  Future<List<AppNotification>> getNotifications({int limit = 50, int offset = 0}) async {
    try {
      final response = await _dio.get(
        '/notifications',
        queryParameters: {'limit': limit, 'offset': offset},
      );
      return (response.data as List).map((json) => AppNotification.fromJson(json)).toList();
    } on DioException catch (e) {
      print('DioError fetching notifications: ${e.response?.data}');
      rethrow;
    }
  }

  Future<void> markRead(String id) async {
    try {
      await _dio.patch('/notifications/$id/read');
    } on DioException catch (e) {
      print('DioError marking notification read: ${e.response?.data}');
      rethrow;
    }
  }

  Future<void> markAllRead() async {
    try {
      await _dio.post('/notifications/read-all');
    } on DioException catch (e) {
      print('DioError marking all notifications read: ${e.response?.data}');
      rethrow;
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      await _dio.delete('/notifications/$id');
    } on DioException catch (e) {
      print('DioError deleting notification: ${e.response?.data}');
      rethrow;
    }
  }

  Future<void> deleteAll() async {
    try {
      await _dio.delete('/notifications');
    } on DioException catch (e) {
      print('DioError deleting all notifications: ${e.response?.data}');
      rethrow;
    }
  }
}
