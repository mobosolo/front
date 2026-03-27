import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:front/features/auth/providers/auth_providers.dart';
import 'package:front/core/theme/app_theme.dart';
import 'package:front/core/widgets/bottom_nav.dart';
import 'package:front/features/merchant/models/merchant_stats_model.dart';
import 'package:front/features/merchant/providers/merchant_providers.dart';
import 'package:front/core/utils/route_refresh_mixin.dart';

class MerchantDashboardScreen extends ConsumerStatefulWidget {
  const MerchantDashboardScreen({super.key});

  @override
  ConsumerState<MerchantDashboardScreen> createState() => _MerchantDashboardScreenState();
}

class _MerchantDashboardScreenState extends ConsumerState<MerchantDashboardScreen> with RouteRefreshMixin {
  MerchantDailyStats? _stats;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  @override
  void onRouteResumed() {
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final merchantService = ref.read(merchantServiceProvider);
      final stats = await merchantService.getDailyStats();
      if (!mounted) return;
      setState(() => _stats = stats);
    } catch (e) {
      if (!mounted) return;
      setState(() => _stats = null);
    } finally {
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final merchant = authState.user?.merchant;
    final merchantStatus = merchant?.status;
    final canCreateBasket = merchantStatus == 'APPROVED';
    final merchantName = merchant?.businessName ?? 'Mon Commerce';

    void onCreateBasketPressed() {
      if (canCreateBasket) {
        context.push('/create-basket');
        return;
      }

      final message = merchantStatus == null
          ? 'Completez votre profil commercant avant de creer un panier.'
          : merchantStatus == 'PENDING'
              ? 'Votre profil commercant est en attente de validation.'
              : 'Votre profil commercant doit etre approuve pour creer un panier.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      bottomNavigationBar: const BottomNav(activeTab: 'baskets', role: 'MERCHANT'),
      body: SafeArea(
        child: ListView(
          children: [
            _header(context, merchantName, onCreateBasketPressed),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text('Statistiques du jour', style: Theme.of(context).textTheme.headlineMedium),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  _StatCard(
                    icon: Icons.shopping_bag_outlined,
                    label: "Paniers vendus aujourd'hui",
                    value: _isLoadingStats ? '--' : (_stats?.basketsSoldToday ?? 0).toString(),
                    color: AppTheme.primary,
                  ),
                  const SizedBox(height: 12),
                  _StatCard(
                    icon: Icons.attach_money,
                    label: "Revenu aujourd'hui",
                    value: _isLoadingStats ? '--' : '${_stats?.revenueToday ?? 0} F',
                    color: AppTheme.secondary,
                  ),
                  const SizedBox(height: 12),
                  _StatCard(
                    icon: Icons.eco,
                    label: 'Nourriture sauvee (kg)',
                    value: _isLoadingStats ? '--' : (_stats?.foodSavedKg ?? 0).toString(),
                    color: AppTheme.success,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text('Actions rapides', style: Theme.of(context).textTheme.headlineMedium),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: _quickAction(
                context,
                onCreateBasketPressed,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, String merchantName, VoidCallback onCreate) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.storefront, color: AppTheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(merchantName, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: AppTheme.success, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Text('Ouvert', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.mutedForeground)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Creer un panier'),
              style: ElevatedButton.styleFrom(shape: const StadiumBorder()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickAction(BuildContext context, VoidCallback onCreate) {
    return InkWell(
      onTap: onCreate,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: AppTheme.primary),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Creer un nouveau panier')),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.mutedForeground)),
        ],
      ),
    );
  }
}
