import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front/core/providers/dio_provider.dart';
import 'package:front/features/merchant/services/merchant_service.dart';

final merchantServiceProvider = Provider<MerchantService>((ref) {
  final dio = ref.watch(dioProvider);
  return MerchantService(dio);
});
