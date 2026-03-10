import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:front/core/providers/location_providers.dart';
import 'package:front/core/theme/app_theme.dart';
import 'package:front/core/widgets/bottom_nav.dart';
import 'package:front/features/auth/providers/auth_providers.dart';
import 'package:front/features/baskets/models/basket_summary_model.dart';
import 'package:front/features/baskets/providers/basket_providers.dart';

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
  int _radiusKm = 10;
  double? _currentLatitude;
  double? _currentLongitude;
  String _locationLabel = 'Localisation en cours...';

  final TextEditingController _maxPriceController = TextEditingController();
  final TextEditingController _radiusController = TextEditingController(text: '10');
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchBaskets();
  }

  @override
  void dispose() {
    _maxPriceController.dispose();
    _radiusController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchBaskets() async {
    setState(() => _isLoading = true);
    try {
      if (_currentLatitude == null || _currentLongitude == null) {
        final locationService = ref.read(locationServiceProvider);
        final location = await locationService.getCurrentLocation();
        if (location != null) {
          _currentLatitude = location.latitude;
          _currentLongitude = location.longitude;
          final address = await locationService.getReadableAddress(
            _currentLatitude!,
            _currentLongitude!,
          );
          _locationLabel = address ?? 'Adresse indisponible';
        } else {
          _locationLabel = 'Position indisponible';
        }
      }

      final basketService = ref.read(basketServiceProvider);
      _baskets = await basketService.getBaskets(
        lat: _currentLatitude,
        lon: _currentLongitude,
        radius: _radiusKm,
        category: _selectedCategory,
        maxPrice: _maxPrice,
      );
    } catch (e) {
      try {
        final basketService = ref.read(basketServiceProvider);
        _baskets = await basketService.getBaskets(
          category: _selectedCategory,
          maxPrice: _maxPrice,
        );
        _locationLabel = 'Position indisponible (liste globale)';
      } catch (fallbackError) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur chargement paniers: ${fallbackError.toString()}')),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _maxPrice = int.tryParse(_maxPriceController.text);
      _radiusKm = int.tryParse(_radiusController.text) ?? 10;
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
              Text('Filtrer les paniers', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Categorie'),
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
              const SizedBox(height: 12),
              TextField(
                controller: _radiusController,
                decoration: const InputDecoration(labelText: 'Rayon (km)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _applyFilters,
                child: const Text('Appliquer'),
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
      bottomNavigationBar: BottomNav(activeTab: 'home', role: user?.role ?? 'CLIENT'),
      body: SafeArea(
        child: ListView(
          children: [
            _Header(
              userName: userName,
              locationLabel: _locationLabel,
              onSearchChanged: (_) => setState(() {}),
              searchController: _searchController,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text('Paniers autour de vous', style: Theme.of(context).textTheme.headlineMedium),
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
                child: Center(child: Text('Aucun panier trouve')),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: _filteredBaskets
                      .map(
                        (basket) => _BasketCard(
                          basket: basket,
                          onTap: () => context.push('/basket-details/${basket.id}'),
                          onReserve: () => context.push(
                            '/select-payment-method',
                            extra: {
                              'basketId': basket.id,
                              'price': basket.discountedPrice,
                              'basketTitle': basket.title,
                              'merchantName': basket.merchant?.businessName,
                              'pickupStart': basket.pickupTimeStart != null ? _formatTime(basket.pickupTimeStart!) : null,
                              'pickupEnd': basket.pickupTimeEnd != null ? _formatTime(basket.pickupTimeEnd!) : null,
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

String _formatTime(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

class _Header extends StatelessWidget {
  final String userName;
  final String locationLabel;
  final ValueChanged<String> onSearchChanged;
  final TextEditingController searchController;

  const _Header({
    required this.userName,
    required this.locationLabel,
    required this.onSearchChanged,
    required this.searchController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4))],
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
                    Text('Bonjour, $userName', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 6),
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.location_on_outlined, size: 16, color: AppTheme.mutedForeground),
                      label: Text(locationLabel),
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
            decoration: const InputDecoration(
              hintText: 'Rechercher un panier ou commerce',
              prefixIcon: Icon(Icons.search),
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
    final isUnavailable = _isUnavailable(basket);
    final unavailableLabel = _unavailableLabel(basket);
    final savings = basket.originalPrice > 0
        ? (((basket.originalPrice - basket.discountedPrice) / basket.originalPrice) * 100).round()
        : 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 160,
                width: double.infinity,
                child: _image(
                  isUnavailable: isUnavailable,
                  label: unavailableLabel,
                  savings: savings,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(basket.title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    if (isUnavailable)
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.destructive.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          unavailableLabel,
                          style: const TextStyle(color: AppTheme.destructive, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    if (basket.merchant?.businessName != null)
                      Text(
                        basket.merchant!.businessName!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.mutedForeground),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (basket.distanceKm != null) ...[
                          const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.mutedForeground),
                          const SizedBox(width: 4),
                          Text(
                            '${basket.distanceKm!.toStringAsFixed(1)} km',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.mutedForeground),
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (basket.pickupTimeStart != null && basket.pickupTimeEnd != null)
                          Text(
                            '${_time(basket.pickupTimeStart!)} - ${_time(basket.pickupTimeEnd!)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.mutedForeground),
                          ),
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
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${basket.discountedPrice} F',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.primary),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: isUnavailable ? null : onReserve,
                          style: ElevatedButton.styleFrom(shape: const StadiumBorder()),
                          child: Text(isUnavailable ? 'Indisponible' : 'Reserver'),
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

  Widget _image({required bool isUnavailable, required String label, required int savings}) {
    final image = basket.photoURL == null || basket.photoURL!.isEmpty
        ? Container(
            color: AppTheme.background,
            child: const Icon(Icons.shopping_basket, color: AppTheme.mutedForeground, size: 40),
          )
        : Image.network(
            basket.photoURL!,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          );

    return Stack(
      fit: StackFit.expand,
      children: [
        image,
        Positioned(
          top: 10,
          right: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              boxShadow: const [
                BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 3)),
              ],
            ),
            child: Text(
              '-$savings%',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        if (isUnavailable) Container(color: Colors.black.withOpacity(0.45)),
        if (isUnavailable)
          Align(
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                label,
                style: const TextStyle(color: AppTheme.destructive, fontWeight: FontWeight.w700),
              ),
            ),
          ),
      ],
    );
  }

  String _time(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  bool _isUnavailable(BasketSummary basket) {
    final status = (basket.status ?? 'AVAILABLE').toUpperCase();
    if (status != 'AVAILABLE') return true;
    if ((basket.availableQuantity ?? 0) <= 0) return true;
    if (basket.pickupTimeEnd != null && basket.pickupTimeEnd!.isBefore(DateTime.now())) return true;
    return false;
  }

  String _unavailableLabel(BasketSummary basket) {
    final status = (basket.status ?? 'AVAILABLE').toUpperCase();
    if (status == 'SOLD_OUT' || (basket.availableQuantity ?? 0) <= 0) return 'Epuise';
    if (status == 'EXPIRED') return 'Termine';
    if (basket.pickupTimeEnd != null && basket.pickupTimeEnd!.isBefore(DateTime.now())) return 'Termine';
    return 'Indisponible';
  }
}
