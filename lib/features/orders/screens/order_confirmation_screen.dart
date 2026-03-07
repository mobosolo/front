import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:front/features/orders/providers/order_providers.dart';
import 'package:front/features/orders/models/order_model.dart';
import 'package:front/core/theme/app_theme.dart';
import 'package:front/core/widgets/bottom_nav.dart';

class OrderConfirmationScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderConfirmationScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderConfirmationScreen> createState() => _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends ConsumerState<OrderConfirmationScreen> {
  Order? _order;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
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
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur lors du chargement des détails de la commande: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
        body: Center(child: Text('Commande non trouvée.')),
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
          Text('Paiement confirmé 🎉', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Présentez ce QR code au commerçant lors du retrait',
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
              onPressed: () {},
              icon: const Icon(Icons.navigation),
              label: const Text("Ouvrir l'itinéraire"),
              style: ElevatedButton.styleFrom(shape: const StadiumBorder()),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.go('/baskets'),
              icon: const Icon(Icons.home, color: AppTheme.primary),
              label: const Text('Retour à l\'accueil'),
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
    if (start == null || end == null) return 'Retrait: —';
    return 'Retrait: ${_time(start)} - ${_time(end)}';
  }

  String _time(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
