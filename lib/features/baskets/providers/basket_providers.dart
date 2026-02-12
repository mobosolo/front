import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front/core/providers/dio_provider.dart';
import 'package:front/features/baskets/services/basket_service.dart';

final basketServiceProvider = Provider<BasketService>((ref) {
  final dio = ref.watch(dioProvider);
  return BasketService(dio);
});
