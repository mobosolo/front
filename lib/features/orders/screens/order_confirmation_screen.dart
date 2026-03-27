import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:front/features/orders/providers/order_providers.dart';
import 'package:front/features/orders/models/order_model.dart';
import 'package:front/core/theme/app_theme.dart';
import 'package:front/core/widgets/bottom_nav.dart';
import 'package:front/core/utils/route_refresh_mixin.dart';

class OrderConfirmationScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderConfirmationScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderConfirmationScreen> createState() => _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends ConsumerState<OrderConfirmationScreen> with RouteRefreshMixin {
  Order? _order;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isRedirecting = false;

  @override
  void initState() {
    super.initState();
    _fetchOrderDetails();
  }

  @override
  void onRouteResumed() {
    _fetchOrderDetails();
  }

  Future<void> _fetchOrderDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final orderService = ref.read(orderServiceProvider);
      _order = await orderService.getOrderDetails(widget.orderId);
      if (mounted && _order?.orderStatus.toUpperCase() == 'PICKED_UP') {
        _isRedirecting = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          context.go('/client-orders?tab=completed&validated=1');
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur lors du chargement des details de la commande: ${e.toString()}';
        });
      }
    } finally {
      if (mounted && !_isRedirecting) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openDirections() async {
    if (_order == null) return;

    final destination = (_order!.merchant?.address ?? '').trim().isNotEmpty
        ? _order!.merchant!.address!.trim()
        : (_order!.merchant?.businessName ?? '').trim();

    if (destination.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adresse du commerce indisponible.')),
      );
      return;
    }

    final encoded = Uri.encodeComponent(destination);
    final mapsUrl = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$encoded');
    final launched = await launchUrl(mapsUrl, mode: LaunchMode.externalApplication);

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Impossible d'ouvrir l'itineraire.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(child: Text(_errorMessage!)),
      );
    }

    if (_order == null) {
      return const Scaffold(
        body: Center(child: Text('Commande non trouvee.')),
      );
    }

    final order = _order!;
    final qrPayload = jsonEncode({'orderId': order.id, 'qrCode': order.qrCode});

    return Scaffold(
      backgroundColor: AppTheme.background,
      bottomNavigationBar: const BottomNav(
        activeTab: 'orders',
        role: 'CLIENT',
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            _successHeader(),
            Expanded(child: _qrCard(qrPayload)),
            _actions(context),
          ],
        ),
      ),
    );
  }

  Widget _successHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(color: AppTheme.success, shape: BoxShape.circle),
            child: const Icon(Icons.check_circle, size: 48, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text('Paiement confirme', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Presentez ce QR code au commercant lors du retrait',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.mutedForeground),
          ),
        ],
      ),
    );
  }

  Widget _qrCard(String payload) {
    final order = _order!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 6)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: QrImageView(
                data: payload,
                version: QrVersions.auto,
                size: 220,
                backgroundColor: Colors.white,
                gapless: false,
              ),
            ),
            const SizedBox(height: 16),
            Text(order.basket?.title ?? 'Panier', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              order.merchant?.businessName ?? 'Commerce',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.mutedForeground),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                _pickupText(),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openDirections,
              icon: const Icon(Icons.navigation),
              label: const Text("Ouvrir l'itineraire"),
              style: ElevatedButton.styleFrom(shape: const StadiumBorder()),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.go('/baskets'),
              icon: const Icon(Icons.home, color: AppTheme.primary),
              label: const Text('Retour a l\'accueil'),
              style: OutlinedButton.styleFrom(
                shape: const StadiumBorder(),
                side: const BorderSide(color: AppTheme.primary),
                foregroundColor: AppTheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _pickupText() {
    final order = _order!;
    final start = order.basket?.pickupTimeStart;
    final end = order.basket?.pickupTimeEnd;
    if (start == null || end == null) return 'Retrait: -';
    return 'Retrait: ${_time(start)} - ${_time(end)}';
  }

  String _time(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
