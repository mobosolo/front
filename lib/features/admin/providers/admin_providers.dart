import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front/core/providers/dio_provider.dart';
import 'package:front/features/admin/services/admin_service.dart';

final adminServiceProvider = Provider<AdminService>((ref) {
  final dio = ref.watch(dioProvider);
  return AdminService(dio);
});
