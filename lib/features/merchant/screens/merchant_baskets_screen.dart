import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:front/features/baskets/providers/basket_providers.dart';
import 'package:front/features/baskets/models/basket_summary_model.dart';
import 'package:front/features/auth/providers/auth_providers.dart';
import 'package:front/core/theme/app_theme.dart';
import 'package:front/core/widgets/bottom_nav.dart';
import 'package:front/core/utils/route_refresh_mixin.dart';

class MerchantBasketsScreen extends ConsumerStatefulWidget {
  const MerchantBasketsScreen({super.key});

  @override
  ConsumerState<MerchantBasketsScreen> createState() => _MerchantBasketsScreenState();
}

class _MerchantBasketsScreenState extends ConsumerState<MerchantBasketsScreen> with RouteRefreshMixin {
  List<BasketSummary> _baskets = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchBaskets();
  }

  @override
  void onRouteResumed() {
    _fetchBaskets();
  }

  Future<void> _fetchBaskets() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final basketService = ref.read(basketServiceProvider);
      final all = await basketService.getBaskets();
      final merchantId = ref.read(authStateProvider).user?.merchant?.id;
      _baskets = merchantId == null ? [] : all.where((b) => b.merchantId == merchantId).toList();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Erreur lors du chargement des paniers: ${e.toString()}";
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onCreate() {
    context.push('/create-basket');
  }

  void _onEdit(String id) {
    context.push('/edit-basket/$id');
  }

  Future<void> _applyQuickUpdate(
    BasketSummary basket, {
    int? delta,
    String? status,
    int? shiftMinutes,
  }) async {
    try {
      final service = ref.read(basketServiceProvider);
      await service.quickUpdateBasket(
        basket.id,
        delta: delta,
        status: status,
        shiftMinutes: shiftMinutes,
      );
      _fetchBaskets();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur mise a jour: ${e.toString()}')),
      );
    }
  }

  Future<void> _onDelete(String id) async {
    try {
      await ref.read(basketServiceProvider).deleteBasket(id);
      _fetchBaskets();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur suppression: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      bottomNavigationBar: const BottomNav(activeTab: 'baskets', role: 'MERCHANT'),
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
            else if (_baskets.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24),
                child: _emptyState(),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: _baskets.map((b) => _basketCard(b)).toList(),
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
      child: Row(
        children: [
          Expanded(child: Text('Mes paniers', style: Theme.of(context).textTheme.headlineMedium)),
          InkWell(
            onTap: _onCreate,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _basketCard(BasketSummary basket) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: SizedBox(
              height: 160,
              width: double.infinity,
              child: _bannerImage(basket),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(basket.title, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 4),
                if (basket.pickupTimeStart != null && basket.pickupTimeEnd != null)
                  Text(
                    '${_time(basket.pickupTimeStart!)} - ${_time(basket.pickupTimeEnd!)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.mutedForeground),
                  ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _quantityLabel(basket),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.mutedForeground)),
                    Text('${basket.discountedPrice} F',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.primary)),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          const Divider(height: 1),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _onEdit(basket.id),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.edit, size: 16, color: AppTheme.primary),
                        SizedBox(width: 6),
                        Text('Modifier', style: TextStyle(color: AppTheme.primary)),
                      ],
                    ),
                  ),
                ),
              ),
              Container(width: 1, color: AppTheme.border),
              Expanded(
                child: InkWell(
                  onTap: () => _onDelete(basket.id),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.delete, size: 16, color: AppTheme.destructive),
                        SizedBox(width: 6),
                        Text('Supprimer', style: TextStyle(color: AppTheme.destructive)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _bannerImage(BasketSummary basket) {
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
      ],
    );
  }

  Widget _thumb(String? url) {
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

  Widget _emptyState() {
    return Column(
      children: [
        const Icon(Icons.inventory_2_outlined, size: 48, color: AppTheme.mutedForeground),
        const SizedBox(height: 12),
        const Text('Aucun panier créé'),
        const SizedBox(height: 6),
        Text(
          'Créez votre premier panier pour commencer à vendre vos invendus.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.mutedForeground),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _onCreate,
          style: ElevatedButton.styleFrom(shape: const StadiumBorder()),
          child: const Text('Créer un panier'),
        ),
      ],
    );
  }

  String _time(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _quantityLabel(BasketSummary basket) {
    final total = basket.quantity ?? 0;
    final available = basket.availableQuantity ?? total;
    if (total > 0 && available >= 0 && available != total) {
      return 'Quantite: $total (Restant: $available)';
    }
    return 'Quantite: $available';
  }
}
