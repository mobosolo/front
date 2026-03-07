import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:front/features/auth/providers/auth_providers.dart';
import 'package:front/core/providers/storage_providers.dart';
import 'package:front/core/theme/app_theme.dart';
import 'package:front/core/widgets/bottom_nav.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Utilisateur non connecté')),
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
            _menuItems(context),
            const SizedBox(height: 12),
            _switchRole(context),
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
                const Text('Client SauvePanier', style: TextStyle(color: Colors.white70)),
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
                  _infoRow(Icons.phone_outlined, 'Téléphone', phone),
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
            _menuRow(Icons.shopping_bag_outlined, 'Mes commandes', () => context.push('/client-orders'), hasBorder: true),
            _menuRow(Icons.settings_outlined, 'Paramètres', () {}),
          ],
        ),
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

  Widget _switchRole(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            backgroundColor: AppTheme.secondary.withOpacity(0.08),
            foregroundColor: AppTheme.secondary,
            side: BorderSide.none,
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: const Text('Passer en mode commerçant'),
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
          label: const Text('Déconnexion', style: TextStyle(color: AppTheme.destructive)),
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
