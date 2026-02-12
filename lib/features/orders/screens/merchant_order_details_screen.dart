import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front/features/orders/providers/order_providers.dart';
import 'package:front/features/orders/models/order_model.dart';

class MerchantOrderDetailsScreen extends ConsumerStatefulWidget {
  final String orderId;

  const MerchantOrderDetailsScreen({super.key, required this.orderId});

  @override
  ConsumerState<MerchantOrderDetailsScreen> createState() => _MerchantOrderDetailsScreenState();
}

class _MerchantOrderDetailsScreenState extends ConsumerState<MerchantOrderDetailsScreen> {
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
          _errorMessage = 'Erreur lors du chargement des détails: ${e.toString()}';
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
      return Scaffold(
        appBar: AppBar(title: const Text('Détails commande')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Détails commande')),
        body: Center(child: Text(_errorMessage!)),
      );
    }

    if (_order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Détails commande')),
        body: const Center(child: Text('Commande introuvable.')),
      );
    }

    final order = _order!;
    return Scaffold(
      appBar: AppBar(title: const Text('Détails commande')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _infoRow('Commande', order.id),
            _infoRow('Statut commande', order.orderStatus),
            _infoRow('Statut paiement', order.paymentStatus),
            _infoRow('Méthode paiement', order.paymentMethod),
            _infoRow('Montant', order.price.toString()),
            if (order.paidAt != null) _infoRow('Payé le', order.paidAt!.toLocal().toString()),
            if (order.pickedUpAt != null) _infoRow('Retiré le', order.pickedUpAt!.toLocal().toString()),
            const Divider(height: 32),
            _infoRow('Client', order.user?.displayName ?? 'N/A'),
            _infoRow('Téléphone client', order.user?.phoneNumber ?? 'N/A'),
            const Divider(height: 32),
            _infoRow('Panier', order.basket?.title ?? order.basketId),
            if (order.basket?.pickupTimeStart != null)
              _infoRow('Début retrait', order.basket!.pickupTimeStart!.toLocal().toString()),
            if (order.basket?.pickupTimeEnd != null)
              _infoRow('Fin retrait', order.basket!.pickupTimeEnd!.toLocal().toString()),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
