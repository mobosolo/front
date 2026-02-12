import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front/core/providers/dio_provider.dart';
import 'package:front/features/orders/services/order_service.dart';

final orderServiceProvider = Provider<OrderService>((ref) {
  final dio = ref.watch(dioProvider);
  return OrderService(dio);
});
