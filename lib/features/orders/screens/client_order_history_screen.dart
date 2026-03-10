import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:front/features/orders/providers/order_providers.dart';
import 'package:front/features/orders/models/order_model.dart';
import 'package:front/core/theme/app_theme.dart';
import 'package:front/core/widgets/bottom_nav.dart';

class ClientOrderHistoryScreen extends ConsumerStatefulWidget {
  final String? initialTab;
  final bool showValidatedMessage;

  const ClientOrderHistoryScreen({
    super.key,
    this.initialTab,
    this.showValidatedMessage = false,
  });

  @override
  ConsumerState<ClientOrderHistoryScreen> createState() => _ClientOrderHistoryScreenState();
}

class _ClientOrderHistoryScreenState extends ConsumerState<ClientOrderHistoryScreen> {
  List<Order> _orders = [];
  bool _isLoading = true;
  String? _errorMessage;
  late String _activeTab; // active | completed | cancelled

  @override
  void initState() {
    super.initState();
    _activeTab = _resolveInitialTab(widget.initialTab);
    _fetchClientOrders();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.showValidatedMessage && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Commande validee. Retrouvez-la dans Terminees.')),
        );
      }
    });
  }

  String _resolveInitialTab(String? initialTab) {
    if (initialTab == 'completed' || initialTab == 'cancelled') {
      return initialTab!;
    }
    return 'active';
  }

  Future<void> _fetchClientOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final orderService = ref.read(orderServiceProvider);
      _orders = await orderService.getClientOrders();
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

  List<Order> get _filteredOrders {
    return _orders.where((order) {
      final status = order.orderStatus.toUpperCase();
      if (_activeTab == 'active') return status == 'RESERVED';
      if (_activeTab == 'completed') return status == 'PICKED_UP';
      return status == 'CANCELLED';
    }).toList();
  }

  Future<void> _cancelOrder(Order order) async {
    try {
      await ref.read(orderServiceProvider).cancelOrder(order.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Commande annulee.')),
      );
      await _fetchClientOrders();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      bottomNavigationBar: const BottomNav(activeTab: 'orders', role: 'CLIENT'),
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
            else if (_filteredOrders.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24),
                child: _emptyState(),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: _filteredOrders
                      .map((order) => _OrderCard(
                            order: order,
                            onTap: _activeTab == 'active' ? () => context.push('/order-confirmation/${order.id}') : null,
                            onCancel: _activeTab == 'active' ? () => _cancelOrder(order) : null,
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
          Text('Mes commandes', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              _tabChip('active', 'Actives'),
              const SizedBox(width: 8),
              _tabChip('completed', 'Terminées'),
              const SizedBox(width: 8),
              _tabChip('cancelled', 'Annulées'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tabChip(String id, String label) {
    final bool selected = _activeTab == id;
    return InkWell(
      onTap: () => setState(() => _activeTab = id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppTheme.mutedForeground,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    final label = _activeTab == 'active'
        ? 'actives'
        : _activeTab == 'completed'
            ? 'terminées'
            : 'annulées';
    return Column(
      children: [
        const Icon(Icons.shopping_bag_outlined, size: 48, color: AppTheme.mutedForeground),
        const SizedBox(height: 12),
        const Text('Aucune commande'),
        const SizedBox(height: 6),
        Text(
          "Vous n'avez pas encore de commandes $label.",
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.mutedForeground),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback? onTap;
  final VoidCallback? onCancel;

  const _OrderCard({required this.order, this.onTap, this.onCancel});

  @override
  Widget build(BuildContext context) {
    final status = order.orderStatus.toUpperCase();
    final statusLabel = status == 'RESERVED'
        ? 'Réservé'
        : status == 'PICKED_UP'
            ? 'Récupéré'
            : 'Annulé';
    final statusColor = status == 'RESERVED'
        ? AppTheme.primary
        : status == 'PICKED_UP'
            ? AppTheme.success
            : AppTheme.destructive;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            children: [
              _thumb(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            order.basket?.title ?? 'Panier',
                            style: Theme.of(context).textTheme.bodyLarge,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (status == 'RESERVED') const Icon(Icons.qr_code, size: 18, color: AppTheme.primary),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.merchant?.businessName ?? 'Commerce',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.mutedForeground),
                    ),
                    const SizedBox(height: 6),
                    if (order.merchant?.address != null)
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.mutedForeground),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              order.merchant!.address!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppTheme.mutedForeground),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text('${order.price} F', style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                    if (status == 'RESERVED' && onCancel != null) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: onCancel,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.destructive,
                            side: const BorderSide(color: AppTheme.destructive),
                          ),
                          child: const Text('Annuler la commande'),
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      _formatDate(order.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.mutedForeground),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumb() {
    final url = order.basket?.photoURL;
    if (url == null || url.isEmpty) {
      return Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.shopping_basket, color: AppTheme.mutedForeground),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(url, width: 72, height: 72, fit: BoxFit.cover),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
