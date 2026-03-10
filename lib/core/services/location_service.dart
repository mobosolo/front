import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class AppLocation {
  final double latitude;
  final double longitude;

  const AppLocation({
    required this.latitude,
    required this.longitude,
  });
}

class LocationService {
  Future<AppLocation?> getCurrentLocation({Duration timeout = const Duration(seconds: 8)}) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(timeout);

      return AppLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {
      return null;
    }
  }

  Future<String?> getReadableAddress(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isEmpty) return null;

      final p = placemarks.first;
      final parts = <String>[
        if ((p.subLocality ?? '').trim().isNotEmpty) p.subLocality!.trim(),
        if ((p.locality ?? '').trim().isNotEmpty) p.locality!.trim(),
        if ((p.country ?? '').trim().isNotEmpty) p.country!.trim(),
      ];

      if (parts.isEmpty) return null;
      return parts.join(', ');
    } catch (_) {
      return null;
    }
  }
}
