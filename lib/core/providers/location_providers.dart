import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front/core/services/location_service.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});
