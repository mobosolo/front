import 'package:dio/dio.dart';
import 'package:front/features/admin/models/admin_models.dart';

class AdminService {
  final Dio _dio;

  AdminService(this._dio);

  Future<AdminStats> getAdminStats() async {
    try {
      final response = await _dio.get('/admin/stats');
      return AdminStats.fromJson(response.data);
    } on DioException catch (e) {
      print('DioError fetching admin stats: ${e.response?.data}');
      rethrow;
    }
  }

  Future<List<AdminMerchant>> getMerchants({String? status}) async {
    try {
      final params = <String, dynamic>{};
      if (status != null && status.isNotEmpty) {
        params['status'] = status;
      }
      final response = await _dio.get('/admin/merchants', queryParameters: params);
      return (response.data as List).map((json) => AdminMerchant.fromJson(json)).toList();
    } on DioException catch (e) {
      print('DioError fetching merchants: ${e.response?.data}');
      rethrow;
    }
  }

  Future<void> approveMerchant(String merchantId) async {
    try {
      await _dio.put('/admin/merchants/$merchantId/approve');
    } on DioException catch (e) {
      print('DioError approving merchant: ${e.response?.data}');
      rethrow;
    }
  }

  Future<void> rejectMerchant(String merchantId) async {
    try {
      await _dio.put('/admin/merchants/$merchantId/reject');
    } on DioException catch (e) {
      print('DioError rejecting merchant: ${e.response?.data}');
      rethrow;
    }
  }

  Future<List<AdminUser>> getUsers({String? role}) async {
    try {
      final params = <String, dynamic>{};
      if (role != null && role.isNotEmpty) {
        params['role'] = role;
      }
      final response = await _dio.get('/admin/users', queryParameters: params);
      return (response.data as List).map((json) => AdminUser.fromJson(json)).toList();
    } on DioException catch (e) {
      print('DioError fetching users: ${e.response?.data}');
      rethrow;
    }
  }
}
