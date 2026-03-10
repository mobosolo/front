import 'package:dio/dio.dart';
import 'package:front/features/merchant/models/merchant_model.dart';
import 'package:front/features/merchant/models/merchant_stats_model.dart';

class MerchantService {
  final Dio _dio;

  MerchantService(this._dio);

  Future<void> registerMerchant({
    required String businessName,
    String? type,
    String? address,
    double? latitude,
    double? longitude,
    String? phoneNumber,
    String? photoURL,
  }) async {
    try {
      final response = await _dio.post(
        '/merchants/register',
        data: {
          'businessName': businessName,
          if (type != null && type.trim().isNotEmpty) 'type': type.trim(),
          if (address != null && address.trim().isNotEmpty) 'address': address.trim(),
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
          if (phoneNumber != null && phoneNumber.trim().isNotEmpty) 'phoneNumber': phoneNumber.trim(),
          if (photoURL != null && photoURL.trim().isNotEmpty) 'photoURL': photoURL.trim(),
        },
      );
      // Register response may only include id/status; no parsing needed here.
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Merchant registration failed with unexpected status.');
      }
    } on DioException catch (e) {
      print('DioError registering merchant: ${e.response?.data}');
      rethrow;
    }
  }

  Future<Merchant> getMyMerchantProfile() async {
    try {
      final response = await _dio.get('/merchants/me');
      return Merchant.fromJson(response.data);
    } on DioException catch (e) {
      print('DioError fetching merchant profile: ${e.response?.data}');
      rethrow;
    }
  }

  Future<Merchant> updateMerchantProfile({
    required String merchantId,
    String? businessName,
    String? type,
    String? address,
    double? latitude,
    double? longitude,
    String? phoneNumber,
    String? photoURL,
  }) async {
    try {
      final response = await _dio.put(
        '/merchants/$merchantId',
        data: {
          if (businessName != null && businessName.trim().isNotEmpty) 'businessName': businessName.trim(),
          if (type != null && type.trim().isNotEmpty) 'type': type.trim(),
          if (address != null && address.trim().isNotEmpty) 'address': address.trim(),
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
          if (phoneNumber != null && phoneNumber.trim().isNotEmpty) 'phoneNumber': phoneNumber.trim(),
          if (photoURL != null && photoURL.trim().isNotEmpty) 'photoURL': photoURL.trim(),
        },
      );
      return Merchant.fromJson(response.data);
    } on DioException catch (e) {
      print('DioError updating merchant profile: ${e.response?.data}');
      rethrow;
    }
  }

  Future<MerchantDailyStats> getDailyStats() async {
    try {
      final response = await _dio.get('/merchants/stats');
      return MerchantDailyStats.fromJson(response.data);
    } on DioException catch (e) {
      print('DioError fetching merchant stats: ${e.response?.data}');
      rethrow;
    }
  }
}
