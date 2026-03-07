import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:front/features/orders/providers/order_providers.dart';
import 'package:front/features/orders/models/order_model.dart';
import 'package:front/core/theme/app_theme.dart';
import 'package:front/core/widgets/bottom_nav.dart';

class MerchantSalesHistoryScreen extends ConsumerStatefulWidget {
  const MerchantSalesHistoryScreen({super.key});

  @override
  ConsumerState<MerchantSalesHistoryScreen> createState() => _MerchantSalesHistoryScreenState();
}

class _MerchantSalesHistoryScreenState extends ConsumerState<MerchantSalesHistoryScreen> {
  List<Order> _orders = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchMerchantOrders();
  }

  Future<void> _fetchMerchantOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final orderService = ref.read(orderServiceProvider);
      _orders = await orderService.getMerchantOrders();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Erreur lors du chargement des commandes: ${e.toString()}";
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Order> get _activeOrders {
    return _orders.where((o) => o.orderStatus.toUpperCase() == 'RESERVED').toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      bottomNavigationBar: const BottomNav(activeTab: 'orders', role: 'MERCHANT'),
      body: SafeArea(
        child: ListView(
          children: [
            _header(),
            const SizedBox(height: 12),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
                child: Center(child: Text(_errorMessage!)),
              )
            else if (_activeOrders.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24),
                child: _emptyState(),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: _activeOrders
                      .map((order) => _OrderCard(
                            order: order,
                            onScan: () => context.push('/qr-scanner'),
                          ))
                      .toList(),
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Commandes', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text(
            'Gérez les réservations de vos paniers',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.mutedForeground),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Column(
      children: [
        const Icon(Icons.shopping_bag_outlined, size: 48, color: AppTheme.mutedForeground),
        const SizedBox(height: 12),
        const Text('Aucune commande active'),
        const SizedBox(height: 6),
        Text(
          "Les nouvelles réservations apparaîtront ici.",
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.mutedForeground),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onScan;

  const _OrderCard({required this.order, required this.onScan});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_outline, color: AppTheme.mutedForeground, size: 18),
              const SizedBox(width: 6),
              Text(order.user?.displayName ?? 'Client',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.mutedForeground)),
            ],
          ),
          const SizedBox(height: 6),
          Text(order.basket?.title ?? 'Panier', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.schedule, size: 16, color: AppTheme.mutedForeground),
              const SizedBox(width: 6),
              Text(
                _pickupText(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.mutedForeground),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Réservé',
                  style: TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w600),
                ),
              ),
              ElevatedButton.icon(
                onPressed: onScan,
                icon: const Icon(Icons.qr_code, size: 18),
                label: const Text('Scanner QR'),
                style: ElevatedButton.styleFrom(shape: const StadiumBorder()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _pickupText() {
    final start = order.basket?.pickupTimeStart;
    final end = order.basket?.pickupTimeEnd;
    if (start == null || end == null) return 'Horaire: —';
    return 'Retrait: ${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')} - '
        '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
  }
}
