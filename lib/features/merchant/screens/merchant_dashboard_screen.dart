import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:front/features/auth/providers/auth_providers.dart';
import 'package:front/core/theme/app_theme.dart';
import 'package:front/core/widgets/bottom_nav.dart';

class MerchantDashboardScreen extends ConsumerWidget {
  const MerchantDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          ? 'Complétez votre profil commerçant avant de créer un panier.'
          : merchantStatus == 'PENDING'
              ? 'Votre profil commerçant est en attente de validation.'
              : 'Votre profil commerçant doit être approuvé pour créer un panier.';

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
                children: const [
                  _StatCard(
                    icon: Icons.shopping_bag_outlined,
                    label: "Paniers vendus aujourd'hui",
                    value: '0',
                    color: AppTheme.primary,
                  ),
                  SizedBox(height: 12),
                  _StatCard(
                    icon: Icons.attach_money,
                    label: "Revenu aujourd'hui",
                    value: '0 F',
                    color: AppTheme.secondary,
                  ),
                  SizedBox(height: 12),
                  _StatCard(
                    icon: Icons.eco,
                    label: 'Nourriture sauvée (kg)',
                    value: '0',
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
              label: const Text('Créer un panier'),
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
            const Expanded(child: Text('Créer un nouveau panier')),
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
