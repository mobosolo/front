import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:front/features/baskets/providers/basket_providers.dart';
import 'package:front/features/baskets/models/basket_summary_model.dart';
import 'package:front/features/auth/providers/auth_providers.dart'; // For user role check
import 'package:front/core/providers/storage_providers.dart';

enum BasketView { listView }

class BasketListScreen extends ConsumerStatefulWidget {
  const BasketListScreen({super.key});

  @override
  ConsumerState<BasketListScreen> createState() => _BasketListScreenState();
}

class _BasketListScreenState extends ConsumerState<BasketListScreen> {
  BasketView _currentView = BasketView.listView;
  bool _isLoadingLocation = false;
  List<BasketSummary> _baskets = [];
  bool _isLoadingBaskets = false;
  String? _selectedCategory;
  int? _maxPrice;

  final TextEditingController _maxPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchBaskets();
  }

  @override
  void dispose() {
    _maxPriceController.dispose();
    super.dispose();
  }

  Future<void> _fetchBaskets() async {
    setState(() => _isLoadingBaskets = true);
    try {
      final basketService = ref.read(basketServiceProvider);
      _baskets = await basketService.getBaskets(
        // Localisation ignorée pour le moment
        category: _selectedCategory,
        maxPrice: _maxPrice,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur de chargement des paniers: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingBaskets = false);
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _maxPrice = int.tryParse(_maxPriceController.text);
    });
    _fetchBaskets();
    // Close filter dialog/sheet if any
    Navigator.of(context).pop();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Filtrer les paniers', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Catégorie',
                  border: OutlineInputBorder(),
                ),
                items: ['SWEET', 'SAVORY', 'MIXED', null] // Include null for "all categories"
                    .map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(category ?? 'Toutes'),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _maxPriceController,
                decoration: const InputDecoration(
                  labelText: 'Prix maximum',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _applyFilters,
                child: const Text('Appliquer les filtres'),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDateTime(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year.toString();
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paniers disponibles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
          ),
          if (user?.role == 'MERCHANT' && user?.merchant?.status == 'APPROVED')
            IconButton(
              icon: const Icon(Icons.dashboard),
              onPressed: () => context.go('/merchant-dashboard'),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(tokenStorageServiceProvider).deleteToken();
              ref.read(authStateProvider.notifier).logout();
              context.go('/login');
            },
          ),
        ],
      ),
      body: _isLoadingLocation
          ? const Center(child: CircularProgressIndicator())
          : _buildListView(),
    );
  }

  Widget _buildListView() {
    if (_isLoadingBaskets) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_baskets.isEmpty) {
      return const Center(child: Text('Aucun panier disponible.'));
    }
    return ListView.builder(
      itemCount: _baskets.length,
      itemBuilder: (context, index) {
        final basket = _baskets[index];
        final subtitleLines = <String>[
          'Prix: ${basket.discountedPrice}€',
          if (basket.distanceKm != null) 'Distance: ${basket.distanceKm!.toStringAsFixed(1)} km',
          if (basket.pickupTimeEnd != null) 'Fin retrait: ${_formatDateTime(basket.pickupTimeEnd!)}',
          if (basket.merchant?.businessName != null) 'Commercant: ${basket.merchant!.businessName}',
        ];
        return ListTile(
          leading: basket.photoURL != null ? Image.network(basket.photoURL!, width: 50, height: 50, fit: BoxFit.cover) : null,
          title: Text(basket.title),
          subtitle: Text(subtitleLines.join('\n')),
          onTap: () {
            context.push('/basket-details/${basket.id}');
          },
        );
      },
    );
  }

  // Map view désactivée tant que la localisation est ignorée.
}
