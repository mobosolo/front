import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:front/features/baskets/providers/basket_providers.dart';
import 'package:front/features/baskets/models/basket_model.dart';
import 'package:front/features/auth/providers/auth_providers.dart';
import 'package:front/core/theme/app_theme.dart';

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
        setState(() => _isLoading = false);
      }
    }
  }

  void _reserveBasket() {
    if (_basket == null) return;
    context.push('/select-payment-method', extra: {'basketId': _basket!.id, 'price': _basket!.discountedPrice});
  }

  void _editBasket(String basketId) {
    context.push('/edit-basket/$basketId');
  }

  Future<void> _deleteBasket(String basketId) async {
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
          context.go('/merchant-dashboard');
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(child: Text(_errorMessage!)),
      );
    }

    if (_basket == null) {
      return const Scaffold(
        body: Center(child: Text('Panier non trouvé.')),
      );
    }

    final basket = _basket!;
    final savings = basket.originalPrice > 0
        ? (((basket.originalPrice - basket.discountedPrice) / basket.originalPrice) * 100).round()
        : 0;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SizedBox.expand(
        child: Stack(
          children: [
            _headerImage(basket),
          Positioned(
            top: 40,
            left: 16,
            child: _circleButton(
              icon: Icons.arrow_back,
              onTap: () => context.pop(),
            ),
          ),
          Positioned(
            top: 40,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                boxShadow: const [
                  BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 4)),
                ],
              ),
              child: Text(
                '-$savings%',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          Positioned.fill(
            top: 220,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(basket.title, style: Theme.of(context).textTheme.headlineMedium),
                        ),
                        if (isOwner) ...[
                          IconButton(
                            onPressed: () => _editBasket(basket.id),
                            icon: const Icon(Icons.edit, color: AppTheme.primary),
                          ),
                          IconButton(
                            onPressed: () => _deleteBasket(basket.id),
                            icon: const Icon(Icons.delete, color: AppTheme.destructive),
                          ),
                        ],
                      ],
                    ),
                    if (basket.merchant?.businessName != null)
                      Text(
                        basket.merchant!.businessName!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.mutedForeground),
                      ),
                    const SizedBox(height: 20),
                    _sectionTitle('Description'),
                    Text(
                      basket.description ?? 'Aucune description',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.mutedForeground),
                    ),
                    const SizedBox(height: 20),
                    _infoCard(
                      icon: Icons.schedule,
                      title: 'Horaire de retrait',
                      body: '${_time(basket.pickupTimeStart)} - ${_time(basket.pickupTimeEnd)}',
                    ),
                    const SizedBox(height: 12),
                    if (basket.merchant?.address != null)
                      _infoCard(
                        icon: Icons.location_on_outlined,
                        title: 'Adresse',
                        body: basket.merchant!.address!,
                      ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 12),
                    _priceRow('Prix original', '${basket.originalPrice} F', muted: true, strike: true),
                    _priceRow('Économie', '-${basket.originalPrice - basket.discountedPrice} F ($savings%)',
                        color: AppTheme.success),
                    _priceRow('Prix final', '${basket.discountedPrice} F',
                        color: AppTheme.primary, bold: true, large: true),
                    const SizedBox(height: 24),
                    if (!isMerchant || !isOwner) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _reserveBasket,
                          style: ElevatedButton.styleFrom(shape: const StadiumBorder()),
                          child: const Text('Réserver maintenant'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            shape: const StadiumBorder(),
                            side: const BorderSide(color: AppTheme.primary),
                          ),
                          child: const Text('Voir le commerce'),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _headerImage(Basket basket) {
    if (basket.photoURL == null || basket.photoURL!.isEmpty) {
      return Container(
        height: 260,
        width: double.infinity,
        color: AppTheme.background,
        child: const Icon(Icons.shopping_basket, size: 64, color: AppTheme.mutedForeground),
      );
    }
    return Image.network(
      basket.photoURL!,
      height: 260,
      width: double.infinity,
      fit: BoxFit.cover,
    );
  }

  Widget _circleButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Icon(icon, size: 20, color: AppTheme.foreground),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }

  Widget _infoCard({required IconData icon, required String title, required String body}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppTheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(body, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.mutedForeground)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value,
      {bool muted = false, bool strike = false, bool bold = false, bool large = false, Color? color}) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: color ?? (muted ? AppTheme.mutedForeground : AppTheme.foreground),
          decoration: strike ? TextDecoration.lineThrough : null,
          fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
          fontSize: large ? 18 : null,
        );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }

  String _time(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
