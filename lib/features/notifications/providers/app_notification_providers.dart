import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front/core/providers/dio_provider.dart';
import 'package:front/features/notifications/services/app_notification_service.dart';

final appNotificationServiceProvider = Provider<AppNotificationService>((ref) {
  final dio = ref.watch(dioProvider);
  return AppNotificationService(dio);
});
