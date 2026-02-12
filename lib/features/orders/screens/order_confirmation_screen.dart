import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:front/features/orders/providers/order_providers.dart';
import 'package:front/features/orders/models/order_model.dart';
import 'package:qr_flutter/qr_flutter.dart'; // For QR code generation

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
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Confirmation de Commande')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Confirmation de Commande')),
        body: Center(
          child: Text(_errorMessage!),
        ),
      );
    }

    if (_order == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Confirmation de Commande')),
        body: Center(
          child: Text('Commande non trouvée.'),
        ),
      );
    }

    final qrPayload = jsonEncode({'orderId': _order!.id, 'qrCode': _order!.qrCode});
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmation de Commande'),
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () => context.go('/baskets'), // Go to client home after confirmation
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.green, size: 80),
              const SizedBox(height: 20),
              Text(
                'Votre commande est confirmée!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Montrez ce QR code au commerçant pour retirer votre panier.',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              // QR Code Display
              QrImageView(
                data: qrPayload,
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
                gapless: false,
              ),
              const SizedBox(height: 30),
              Text('ID Commande: ${_order!.id}'),
              Text(_order!.basket?.title != null ? 'Panier: ${_order!.basket!.title}' : 'Panier: ${_order!.basketId}'),
              Text('Prix payé: ${_order!.price}€'),
              Text('Méthode de paiement: ${_order!.paymentMethod}'),
              Text('Statut du paiement: ${_order!.paymentStatus}'),
              Text('Statut de la commande: ${_order!.orderStatus}'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => context.go('/baskets'),
                child: const Text('Retour à la liste des paniers'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
