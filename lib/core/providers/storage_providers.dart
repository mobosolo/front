import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front/core/storage/token_storage_service.dart';

final tokenStorageServiceProvider = Provider<TokenStorageService>((ref) {
  return TokenStorageService();
});
