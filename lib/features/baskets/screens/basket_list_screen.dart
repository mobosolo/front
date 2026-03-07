import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:front/features/baskets/providers/basket_providers.dart';
import 'package:front/features/baskets/models/basket_summary_model.dart';
import 'package:front/features/auth/providers/auth_providers.dart';
import 'package:front/core/providers/storage_providers.dart';
import 'package:front/core/theme/app_theme.dart';
import 'package:front/core/widgets/bottom_nav.dart';

class BasketListScreen extends ConsumerStatefulWidget {
  const BasketListScreen({super.key});

  @override
  ConsumerState<BasketListScreen> createState() => _BasketListScreenState();
}

class _BasketListScreenState extends ConsumerState<BasketListScreen> {
  List<BasketSummary> _baskets = [];
  bool _isLoading = false;
  String? _selectedCategory;
  int? _maxPrice;
  final TextEditingController _maxPriceController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchBaskets();
  }

  @override
  void dispose() {
    _maxPriceController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchBaskets() async {
    setState(() => _isLoading = true);
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
          SnackBar(
            content: Text('Erreur de chargement des paniers: ${e.toString()}'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      _maxPrice = int.tryParse(_maxPriceController.text);
    });
    _fetchBaskets();
    Navigator.of(context).pop();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Filtrer les paniers',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Catégorie'),
                items: ['SWEET', 'SAVORY', 'MIXED', null]
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(category ?? 'Toutes'),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _selectedCategory = value),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _maxPriceController,
                decoration: const InputDecoration(labelText: 'Prix maximum'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
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

  List<BasketSummary> get _filteredBaskets {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _baskets;
    return _baskets.where((basket) {
      final title = basket.title.toLowerCase();
      final merchant = basket.merchant?.businessName?.toLowerCase() ?? '';
      return title.contains(query) || merchant.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;
    final userName = user?.displayName?.split(' ').first ?? 'Utilisateur';

    return Scaffold(
      backgroundColor: AppTheme.background,
      bottomNavigationBar: BottomNav(
        activeTab: 'home',
        role: user?.role ?? 'CLIENT',
      ),
      body: SafeArea(
        child: ListView(
          children: [
            _Header(
              userName: userName,
              onSearchChanged: (_) => setState(() {}),
              searchController: _searchController,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'Paniers disponibles',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_filteredBaskets.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Center(child: Text('Aucun panier trouvé')),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: _filteredBaskets
                      .map(
                        (basket) => _BasketCard(
                          basket: basket,
                          onTap: () =>
                              context.push('/basket-details/${basket.id}'),
                          onReserve: () => context.push(
                            '/select-payment-method',
                            extra: {
                              'basketId': basket.id,
                              'price': basket.discountedPrice,
                            },
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String userName;
  final ValueChanged<String> onSearchChanged;
  final TextEditingController searchController;

  const _Header({
    required this.userName,
    required this.onSearchChanged,
    required this.searchController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bonjour, $userName 👋',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 6),
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: AppTheme.mutedForeground,
                      ),
                      label: const Text('Lomé, Togo'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.mutedForeground,
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Rechercher un panier ou commerce',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: AppTheme.background,
            ),
          ),
        ],
      ),
    );
  }
}

class _BasketCard extends StatelessWidget {
  final BasketSummary basket;
  final VoidCallback onTap;
  final VoidCallback onReserve;

  const _BasketCard({
    required this.basket,
    required this.onTap,
    required this.onReserve,
  });

  @override
  Widget build(BuildContext context) {
    final status = _statusLabel();
    final statusColor = _statusColor();
    final savings = basket.originalPrice > 0
        ? (((basket.originalPrice - basket.discountedPrice) /
                      basket.originalPrice) *
                  100)
              .round()
        : 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.border),
        ),
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(height: 160, width: double.infinity, child: _image()),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 12,
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '-$savings%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    basket.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  if (basket.merchant?.businessName != null)
                    Text(
                      basket.merchant!.businessName!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.mutedForeground,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (basket.distanceKm != null) ...[
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: AppTheme.mutedForeground,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${basket.distanceKm!.toStringAsFixed(1)} km',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.mutedForeground),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (basket.pickupTimeStart != null &&
                          basket.pickupTimeEnd != null) ...[
                        const Icon(
                          Icons.schedule,
                          size: 14,
                          color: AppTheme.mutedForeground,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_time(basket.pickupTimeStart!)} - ${_time(basket.pickupTimeEnd!)}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.mutedForeground),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${basket.originalPrice} F',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Colors.grey,
                                  decoration: TextDecoration.lineThrough,
                                ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${basket.discountedPrice} F',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: AppTheme.primary),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: onReserve,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: const StadiumBorder(),
                        ),
                        child: const Text('Réserver'),
                      ),
                    ],
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

  Widget _image() {
    if (basket.photoURL == null || basket.photoURL!.isEmpty) {
      return Container(
        color: AppTheme.background,
        child: const Icon(
          Icons.shopping_basket,
          color: AppTheme.mutedForeground,
          size: 40,
        ),
      );
    }
    return ClipRRect(
      child: Image.network(
        basket.photoURL!,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }

  String _time(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _statusLabel() {
    final status = (basket.status ?? 'AVAILABLE').toUpperCase();
    final qty = basket.availableQuantity ?? 0;
    if (status == 'SOLD_OUT') return 'Épuisé';
    if (status == 'EXPIRED') return 'Expiré';
    if (qty > 0 && qty <= 3) return 'Derniers paniers';
    return 'Disponible';
  }

  Color _statusColor() {
    final status = (basket.status ?? 'AVAILABLE').toUpperCase();
    final qty = basket.availableQuantity ?? 0;
    if (status == 'SOLD_OUT' || status == 'EXPIRED')
      return AppTheme.destructive;
    if (qty > 0 && qty <= 3) return AppTheme.secondary;
    return AppTheme.success;
  }
}
