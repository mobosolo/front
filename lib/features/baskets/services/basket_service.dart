import 'package:dio/dio.dart';
import 'package:front/features/baskets/models/basket_model.dart';
import 'package:front/features/baskets/models/basket_summary_model.dart';

class BasketService {
  final Dio _dio;

  BasketService(this._dio);

  Future<void> createBasket({
    required String title,
    String? description,
    required String category,
    required int originalPrice,
    required int discountedPrice,
    required int quantity,
    required DateTime pickupTimeStart,
    required DateTime pickupTimeEnd,
    String? photoURL,
  }) async {
    try {
      final data = <String, dynamic>{
        'title': title,
        'category': category,
        'originalPrice': originalPrice,
        'discountedPrice': discountedPrice,
        'quantity': quantity,
        'pickupTimeStart': pickupTimeStart.toIso8601String(),
        'pickupTimeEnd': pickupTimeEnd.toIso8601String(),
      };
      if (description != null && description.trim().isNotEmpty) {
        data['description'] = description.trim();
      }
      if (photoURL != null && photoURL.trim().isNotEmpty) {
        data['photoURL'] = photoURL.trim();
      }

      final response = await _dio.post(
        '/baskets',
        data: data,
      );
      // Backend returns a partial basket object on create; no parsing needed here.
      if (response.statusCode != 201) {
        throw Exception('Basket creation failed with unexpected status.');
      }
    } on DioException catch (e) {
      print('DioError creating basket: ${e.response?.data}');
      rethrow;
    }
  }

  Future<List<BasketSummary>> getBaskets({
    double? lat,
    double? lon,
    int? radius,
    String? category,
    int? maxPrice,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (lat != null && lon != null && radius != null) {
        params['lat'] = lat;
        params['lon'] = lon;
        params['radius'] = radius;
      }
      if (category != null && category.isNotEmpty) {
        params['category'] = category;
      }
      if (maxPrice != null) {
        params['maxPrice'] = maxPrice;
      }

      final response = await _dio.get(
        '/baskets',
        queryParameters: params,
      );
      return (response.data as List).map((json) => BasketSummary.fromJson(json)).toList();
    } on DioException catch (e) {
      print('DioError fetching baskets: type=${e.type}, message=${e.message}, data=${e.response?.data}');
      rethrow;
    }
  }

  Future<Basket> getBasketDetails(String id) async {
    try {
      final response = await _dio.get('/baskets/$id');
      return Basket.fromJson(response.data);
    } on DioException catch (e) {
      print('DioError fetching basket details: ${e.response?.data}');
      rethrow;
    }
  }

  Future<Basket> updateBasket(
    String id, {
    required String title,
    String? description,
    required String category,
    required int originalPrice,
    required int discountedPrice,
    required int quantity,
    required DateTime pickupTimeStart,
    required DateTime pickupTimeEnd,
    String? photoURL,
  }) async {
    try {
      final data = <String, dynamic>{
        'title': title,
        'category': category,
        'originalPrice': originalPrice,
        'discountedPrice': discountedPrice,
        'quantity': quantity,
        'pickupTimeStart': pickupTimeStart.toIso8601String(),
        'pickupTimeEnd': pickupTimeEnd.toIso8601String(),
      };
      if (description != null && description.trim().isNotEmpty) {
        data['description'] = description.trim();
      }
      if (photoURL != null && photoURL.trim().isNotEmpty) {
        data['photoURL'] = photoURL.trim();
      }

      final response = await _dio.put(
        '/baskets/$id',
        data: data,
      );
      final payload = response.data is Map<String, dynamic> ? response.data : <String, dynamic>{};
      final basketJson = payload['basket'] is Map<String, dynamic>
          ? payload['basket'] as Map<String, dynamic>
          : payload;
      return Basket.fromJson(basketJson);
    } on DioException catch (e) {
      print('DioError updating basket: ${e.response?.data}');
      rethrow;
    }
  }

  Future<void> deleteBasket(String id) async {
    try {
      await _dio.delete('/baskets/$id');
    } on DioException catch (e) {
      print('DioError deleting basket: ${e.response?.data}');
      rethrow;
    }
  }

  Future<Basket> quickUpdateBasket(
    String id, {
    int? delta,
    String? status,
    int? shiftMinutes,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (delta != null) payload['delta'] = delta;
      if (status != null) payload['status'] = status;
      if (shiftMinutes != null) payload['shiftMinutes'] = shiftMinutes;

      final response = await _dio.patch(
        '/baskets/$id/quick',
        data: payload,
      );
      final data = response.data is Map<String, dynamic> ? response.data : <String, dynamic>{};
      final basketJson = data['basket'] is Map<String, dynamic>
          ? data['basket'] as Map<String, dynamic>
          : data;
      return Basket.fromJson(basketJson);
    } on DioException catch (e) {
      print('DioError quick update basket: ${e.response?.data}');
      rethrow;
    }
  }

  Future<Basket> duplicateBasket(String id) async {
    try {
      final response = await _dio.post('/baskets/$id/duplicate');
      final data = response.data is Map<String, dynamic> ? response.data : <String, dynamic>{};
      final basketJson = data['basket'] is Map<String, dynamic>
          ? data['basket'] as Map<String, dynamic>
          : data;
      return Basket.fromJson(basketJson);
    } on DioException catch (e) {
      print('DioError duplicating basket: ${e.response?.data}');
      rethrow;
    }
  }
}
