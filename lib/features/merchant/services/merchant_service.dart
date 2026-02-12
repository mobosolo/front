import 'package:dio/dio.dart';
import 'package:front/features/merchant/models/merchant_model.dart';

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
          'type': type,
          'address': address,
          'latitude': latitude,
          'longitude': longitude,
          'phoneNumber': phoneNumber,
          'photoURL': photoURL,
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
          'businessName': businessName,
          'type': type,
          'address': address,
          'latitude': latitude,
          'longitude': longitude,
          'phoneNumber': phoneNumber,
          'photoURL': photoURL,
        },
      );
      return Merchant.fromJson(response.data);
    } on DioException catch (e) {
      print('DioError updating merchant profile: ${e.response?.data}');
      rethrow;
    }
  }
}
