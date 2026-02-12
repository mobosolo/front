import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front/core/providers/dio_provider.dart';
import 'package:front/core/services/upload_service.dart';

final uploadServiceProvider = Provider<UploadService>((ref) {
  final dio = ref.watch(dioProvider);
  return UploadService(dio);
});
