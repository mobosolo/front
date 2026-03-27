import 'package:dio/dio.dart';
import 'package:front/features/orders/models/order_model.dart';

class OrderService {
  final Dio _dio;

  OrderService(this._dio);

  Future<Map<String, dynamic>> createOrder({
    required String basketId,
    required String paymentMethod,
  }) async {
    try {
      final response = await _dio.post(
        '/orders',
        data: {
          'basketId': basketId,
          'paymentMethod': paymentMethod,
        },
      );
      // API response includes order and paymentUrl
      return response.data;
    } on DioException catch (e) {
      print('DioError creating order: ${e.response?.data}');
      rethrow;
    }
  }

  Future<Order> getOrderDetails(String id) async {
    try {
      final response = await _dio.get('/orders/$id');
      return Order.fromJson(response.data);
    } on DioException catch (e) {
      print('DioError fetching order details: ${e.response?.data}');
      rethrow;
    }
  }

  Future<List<Order>> getClientOrders() async {
    try {
      final response = await _dio.get('/orders/my-orders');
      return (response.data as List).map((json) => Order.fromJson(json)).toList();
    } on DioException catch (e) {
      print('DioError fetching client orders: ${e.response?.data}');
      rethrow;
    }
  }

  Future<List<Order>> getMerchantOrders() async {
    try {
      final response = await _dio.get('/merchants/orders');
      return (response.data as List).map((json) => Order.fromJson(json)).toList();
    } on DioException catch (e) {
      print('DioError fetching merchant orders: ${e.response?.data}');
      rethrow;
    }
  }

  Future<void> validatePickup(String orderId, String qrCode) async {
    try {
      await _dio.post(
        '/orders/$orderId/pickup',
        data: {
          'qrCode': qrCode,
        },
      );
    } on DioException catch (e) {
      print('DioError validating pickup: ${e.response?.data}');
      rethrow;
    }
  }

  Future<void> cancelOrder(String orderId) async {
    try {
      await _dio.post('/orders/$orderId/cancel');
    } on DioException catch (e) {
      print('DioError cancelling order: ${e.response?.data}');
      rethrow;
    }
  }

  Future<void> confirmPayment(String orderId, {String? transactionRef}) async {
    try {
      await _dio.post(
        '/orders/$orderId/confirm-payment',
        data: {
          if (transactionRef != null) 'transactionRef': transactionRef,
        },
      );
    } on DioException catch (e) {
      print('DioError confirming payment: ${e.response?.data}');
      rethrow;
    }
  }

  // TODO: Add methods for validatePickup
}
