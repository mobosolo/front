import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:front/features/auth/providers/auth_providers.dart';
import 'package:front/core/providers/storage_providers.dart';
import 'package:front/core/theme/app_theme.dart';
import 'package:front/core/widgets/bottom_nav.dart';
import 'package:front/features/orders/providers/order_providers.dart';
import 'package:front/features/orders/models/order_model.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Utilisateur non connecte')),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      bottomNavigationBar: const BottomNav(activeTab: 'profile', role: 'CLIENT'),
      body: SafeArea(
        child: ListView(
          children: [
            _header(context, user.displayName ?? 'Utilisateur'),
            const SizedBox(height: 8),
            _contactInfo(context, user.email, user.phoneNumber),
            const SizedBox(height: 8),
            _savingsCard(ref),
            const SizedBox(height: 8),
            _menuItems(context),
            const SizedBox(height: 8),
            _logout(context, ref),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, String name) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Profil', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, Color(0xCC1E7F5C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 12),
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                const Text('Client MealFlavor', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactInfo(BuildContext context, String email, String? phone) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Informations de contact', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                _infoRow(Icons.mail_outline, 'Email', email, hasBorder: phone != null && phone.isNotEmpty),
                if (phone != null && phone.isNotEmpty)
                  _infoRow(Icons.phone_outlined, 'Telephone', phone),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {bool hasBorder = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: hasBorder ? const Border(bottom: BorderSide(color: AppTheme.border)) : null,
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.mutedForeground),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.mutedForeground)),
              Text(value),
            ],
          ),
        ],
      ),
    );
  }

  Widget _menuItems(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            _menuRow(Icons.shopping_bag_outlined, 'Mes commandes', () => context.push('/client-orders')),
            const Divider(height: 1, color: AppTheme.border),
            _menuRow(Icons.notifications_outlined, 'Notifications', () => context.push('/notifications')),
          ],
        ),
      ),
    );
  }

  Widget _savingsCard(WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: FutureBuilder<List<Order>>(
        future: ref.read(orderServiceProvider).getClientOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _savingsContainer(
              context,
              title: 'Economies realisees',
              value: 'Chargement...',
              subtitle: 'Calcul en cours',
            );
          }
          if (snapshot.hasError) {
            return _savingsContainer(
              context,
              title: 'Economies realisees',
              value: '—',
              subtitle: 'Impossible de charger',
            );
          }

          final orders = snapshot.data ?? [];
          int totalSaved = 0;
          int countedOrders = 0;
          final recentSavings = <int>[];
          final recentPercents = <int>[];

          for (final order in orders) {
            final status = order.orderStatus.toUpperCase();
            if (status != 'PICKED_UP') continue;

            final original = order.basket?.originalPrice;
            final discounted = order.basket?.discountedPrice ?? order.price;
            if (original != null && original > discounted) {
              totalSaved += (original - discounted);
              countedOrders += 1;
              if (recentSavings.length < 7) {
                recentSavings.add(original - discounted);
                final percent = (((original - discounted) / original) * 100).round();
                recentPercents.add(percent);
              }
            }
          }
          final avgSaved = countedOrders > 0 ? (totalSaved / countedOrders).round() : 0;
          final avgPercent = recentPercents.isNotEmpty
              ? (recentPercents.reduce((a, b) => a + b) / recentPercents.length).round()
              : 0;

          return _savingsContainer(
            context,
            title: 'Economies realisees',
            value: '$totalSaved F',
            subtitle: countedOrders > 0 ? '$countedOrders commande(s) retiree(s)' : 'Aucune economie pour l\'instant',
            average: countedOrders > 0 ? 'Moyenne: $avgSaved F' : null,
            percent: countedOrders > 0 ? 'Reduction moyenne: $avgPercent%' : null,
            chartValues: recentSavings,
          );
        },
      ),
    );
  }

  Widget _savingsContainer(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    String? average,
    String? percent,
    List<int> chartValues = const [],
  }) {
    return Container(
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.savings_outlined, color: AppTheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(color: AppTheme.primary, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: AppTheme.mutedForeground)),
                if (average != null) ...[
                  const SizedBox(height: 6),
                  Text(average, style: const TextStyle(color: AppTheme.mutedForeground)),
                ],
                if (percent != null) ...[
                  const SizedBox(height: 4),
                  Text(percent, style: const TextStyle(color: AppTheme.mutedForeground)),
                ],
                if (chartValues.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _miniBarChart(chartValues),
                ] else ...[
                  const SizedBox(height: 10),
                  Text('Aucun historique pour le graphique', style: const TextStyle(color: AppTheme.mutedForeground)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniBarChart(List<int> values) {
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: 36,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: values.map((v) {
          final height = maxValue > 0 ? (v / maxValue) * 36 : 4.0;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Container(
                height: height.clamp(4.0, 36.0),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _menuRow(IconData icon, String label, VoidCallback onTap, {bool hasBorder = false}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: hasBorder ? const Border(bottom: BorderSide(color: AppTheme.border)) : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.mutedForeground),
            const SizedBox(width: 12),
            Expanded(child: Text(label)),
          ],
        ),
      ),
    );
  }

  Widget _logout(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () async {
            await ref.read(tokenStorageServiceProvider).deleteToken();
            ref.read(authStateProvider.notifier).logout();
            context.go('/login');
          },
          icon: const Icon(Icons.logout, color: AppTheme.destructive),
          label: const Text('Deconnexion', style: TextStyle(color: AppTheme.destructive)),
          style: OutlinedButton.styleFrom(
            side: BorderSide.none,
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }
}
