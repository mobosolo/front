import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:front/features/baskets/providers/basket_providers.dart';
import 'package:front/features/baskets/models/basket_model.dart';
import 'package:front/features/auth/providers/auth_providers.dart'; // Import for authStateProvider
import 'package:front/features/orders/providers/order_providers.dart'; // Import OrderService provider

class BasketDetailsScreen extends ConsumerStatefulWidget {
  final String basketId;

  const BasketDetailsScreen({super.key, required this.basketId});

  @override
  ConsumerState<BasketDetailsScreen> createState() => _BasketDetailsScreenState();
}

class _BasketDetailsScreenState extends ConsumerState<BasketDetailsScreen> {
  Basket? _basket;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchBasketDetails();
  }

  Future<void> _fetchBasketDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final basketService = ref.read(basketServiceProvider);
      _basket = await basketService.getBasketDetails(widget.basketId);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur lors du chargement des détails du panier: ${e.toString()}';
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

  void _reserveBasket() {
    if (_basket == null) return;
    context.push('/select-payment-method', extra: {'basketId': _basket!.id, 'price': _basket!.discountedPrice});
  }

  void _editBasket(BuildContext context, String basketId) {
    context.push('/edit-basket/$basketId');
  }

  Future<void> _deleteBasket(BuildContext context, String basketId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmer la suppression'),
          content: const Text('Êtes-vous sûr de vouloir supprimer ce panier ?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await ref.read(basketServiceProvider).deleteBasket(basketId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Panier supprimé avec succès!')),
          );
          context.go('/merchant-dashboard'); // Go back to dashboard after deletion
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur lors de la suppression du panier: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final currentUser = authState.user;
    final bool isMerchant = currentUser?.role == 'MERCHANT';
    final bool isOwner = isMerchant && currentUser?.merchant?.id == _basket?.merchantId;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Détails du Panier')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Détails du Panier')),
        body: Center(
          child: Text(_errorMessage!),
        ),
      );
    }

    if (_basket == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Détails du Panier')),
        body: Center(
          child: Text('Panier non trouvé.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_basket!.title),
        actions: isOwner
            ? [
                IconButton(icon: const Icon(Icons.edit), onPressed: () => _editBasket(context, _basket!.id)),
                IconButton(icon: const Icon(Icons.delete), onPressed: () => _deleteBasket(context, _basket!.id)),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_basket!.photoURL != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  _basket!.photoURL!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 16),
            Text(
              _basket!.title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _basket!.description ?? 'Aucune description',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            _buildDetailRow(context, Icons.category, 'Catégorie', _basket!.category ?? 'N/A'),
            if (_basket!.merchant?.businessName != null)
              _buildDetailRow(context, Icons.store, 'Commerçant', _basket!.merchant!.businessName!),
            if (_basket!.merchant?.address != null)
              _buildDetailRow(context, Icons.place, 'Adresse', _basket!.merchant!.address!),
            _buildDetailRow(context, Icons.money_off, 'Prix original', '${_basket!.originalPrice}€'),
            _buildDetailRow(context, Icons.price_change, 'Prix réduit', '${_basket!.discountedPrice}€', boldValue: true),
            _buildDetailRow(context, Icons.numbers, 'Quantité disponible', '${_basket!.availableQuantity} / ${_basket!.quantity}'),
            _buildDetailRow(context, Icons.access_time, 'Début de retrait', _basket!.pickupTimeStart.toLocalFormattedString()),
            _buildDetailRow(context, Icons.access_time_filled, 'Fin de retrait', _basket!.pickupTimeEnd.toLocalFormattedString()),
            _buildDetailRow(context, Icons.info, 'Statut', _basket!.status),
            const SizedBox(height: 24),
            if (!isMerchant || !isOwner) // Only show reserve button for clients or non-owners
              Center(
                child: ElevatedButton(
                  onPressed: _reserveBasket,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text('Réserver ce panier'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value, {bool boldValue = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text('$label: ', style: Theme.of(context).textTheme.bodyMedium),
          Expanded(
            child: Text(
              value,
              style: boldValue
                  ? Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)
                  : Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

extension on DateTime {
  String toLocalFormattedString() {
    return '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/${year} ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}
