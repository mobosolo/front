import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:front/core/providers/location_providers.dart';
import 'package:front/core/theme/app_theme.dart';
import 'package:front/core/widgets/bottom_nav.dart';
import 'package:front/features/baskets/models/basket_summary_model.dart';
import 'package:front/features/baskets/providers/basket_providers.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends ConsumerStatefulWidget {
  final double? targetLat;
  final double? targetLon;
  final String? targetLabel;
  final String? targetBasketId;

  const MapScreen({
    super.key,
    this.targetLat,
    this.targetLon,
    this.targetLabel,
    this.targetBasketId,
  });

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<BasketSummary> _baskets = [];
  double? _lat;
  double? _lon;
  int _radiusKm = 10;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _loadMapData();
  }

  Future<void> _loadMapData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final location = await ref.read(locationServiceProvider).getCurrentLocation();
      if (location != null) {
        _lat = location.latitude;
        _lon = location.longitude;
      }

      final searchLat = widget.targetLat ?? _lat;
      final searchLon = widget.targetLon ?? _lon;

      if (searchLat == null || searchLon == null) {
        setState(() {
          _errorMessage = 'Impossible de recuperer votre position.';
          _isLoading = false;
        });
        return;
      }

      final baskets = await ref.read(basketServiceProvider).getBaskets(
            lat: searchLat,
            lon: searchLon,
            radius: _radiusKm,
          );

      setState(() {
        _baskets = baskets;
        _isLoading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final focusLat = widget.targetLat ?? _lat;
        final focusLon = widget.targetLon ?? _lon;
        if (focusLat != null && focusLon != null) {
          _mapController.move(LatLng(focusLat, focusLon), 15);
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur carte: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    if (widget.targetLat != null && widget.targetLon != null) {
      markers.add(
        Marker(
          point: LatLng(widget.targetLat!, widget.targetLon!),
          width: 44,
          height: 44,
          child: GestureDetector(
            onTap: () {
              final id = widget.targetBasketId;
              if (id != null && id.isNotEmpty) {
                context.push('/basket-details/$id');
              }
            },
            child: Tooltip(
              message: widget.targetLabel ?? 'Commerce',
              child: const Icon(Icons.storefront, color: AppTheme.secondary, size: 36),
            ),
          ),
        ),
      );
    }

    if (_lat != null && _lon != null) {
      markers.add(
        Marker(
          point: LatLng(_lat!, _lon!),
          width: 36,
          height: 36,
          child: const Icon(Icons.my_location, color: Colors.blue, size: 30),
        ),
      );
    }

    for (final basket in _baskets) {
      final mLat = basket.merchant?.latitude;
      final mLon = basket.merchant?.longitude;
      if (mLat == null || mLon == null) continue;

      markers.add(
        Marker(
          point: LatLng(mLat, mLon),
          width: 36,
          height: 36,
          child: GestureDetector(
            onTap: () => context.push('/basket-details/${basket.id}'),
            child: Tooltip(
              message: '${basket.title} - ${basket.discountedPrice} F',
              child: const Icon(Icons.location_pin, color: AppTheme.primary, size: 34),
            ),
          ),
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final initialLat = widget.targetLat ?? _lat ?? 6.1319;
    final initialLon = widget.targetLon ?? _lon ?? 1.2228;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Carte'),
        actions: [
          IconButton(
            onPressed: _loadMapData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNav(
        activeTab: 'map',
        role: 'CLIENT',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: LatLng(initialLat, initialLon),
                        initialZoom: 13,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.front',
                        ),
                        MarkerLayer(markers: _buildMarkers()),
                      ],
                    ),
                    Positioned(
                      left: 12,
                      right: 12,
                      top: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(color: Color(0x22000000), blurRadius: 10, offset: Offset(0, 4)),
                          ],
                        ),
                        child: Text(
                          '${_baskets.length} panier(s) dans un rayon de $_radiusKm km',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
