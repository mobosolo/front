import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:front/features/orders/providers/order_providers.dart';
import 'package:front/features/orders/models/order_model.dart';
import 'package:front/features/baskets/screens/basket_details_screen.dart'; // For DateTime extension

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
          _errorMessage = "Erreur lors du chargement de l'historique des ventes: ${e.toString()}";
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
        appBar: AppBar(title: Text('Historique des Ventes')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Historique des Ventes')),
        body: Center(
          child: Text(_errorMessage!),
        ),
      );
    }

    if (_orders.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Historique des Ventes')),
        body: const Center(
          child: Text('Vous n\'avez pas encore de ventes.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des Ventes'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _orders.length,
        itemBuilder: (context, index) {
          final order = _orders[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: ListTile(
              title: Text('Commande #${order.id.substring(0, 8)}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order.basket?.title != null
                      ? 'Panier: ${order.basket!.title}'
                      : 'Panier ID: ${order.basketId.substring(0, 8)}'),
                  Text('Prix: ${order.price}€'),
                  Text('Statut: ${order.orderStatus}'),
                  Text('Date: ${order.createdAt.toLocal()}'),
                  if (order.pickedUpAt != null)
                    Text('Retiré le: ${order.pickedUpAt!.toLocal()}'),
                ],
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                context.push('/merchant-orders/${order.id}');
              },
            ),
          );
        },
      ),
    );
  }
}
