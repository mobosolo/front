import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:front/core/theme/app_theme.dart';

class BottomNav extends StatelessWidget {
  final String activeTab;
  final String role; // 'CLIENT' or 'MERCHANT'

  const BottomNav({
    super.key,
    required this.activeTab,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = role == 'CLIENT' ? _clientTabs : _merchantTabs;

    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppTheme.border)),
        ),
        padding: const EdgeInsets.only(bottom: 8),
        height: 64,
        child: Row(
          children: tabs.map((tab) {
            final bool isActive = tab.id == activeTab;
            return Expanded(
              child: InkWell(
                onTap: () => _navigate(context, tab.id),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(tab.icon, size: 24, color: isActive ? AppTheme.primary : Colors.grey[600]),
                    const SizedBox(height: 4),
                    Text(
                      tab.label,
                      style: TextStyle(
                        fontSize: 12,
                        color: isActive ? AppTheme.primary : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _navigate(BuildContext context, String tabId) {
    if (role == 'CLIENT') {
      switch (tabId) {
        case 'home':
          context.go('/baskets');
          return;
        case 'map':
          context.go('/map');
          return;
        case 'orders':
          context.go('/client-orders');
          return;
        case 'profile':
          context.go('/profile');
          return;
      }
    } else {
      switch (tabId) {
        case 'baskets':
          context.go('/merchant-baskets');
          return;
        case 'orders':
          context.go('/merchant-sales');
          return;
        case 'scan':
          context.go('/qr-scanner');
          return;
        case 'profile':
          context.go('/merchant-profile');
          return;
      }
    }
  }
}

class _NavTab {
  final String id;
  final String label;
  final IconData icon;

  const _NavTab({required this.id, required this.label, required this.icon});
}

const List<_NavTab> _clientTabs = [
  _NavTab(id: 'home', label: 'Accueil', icon: Icons.home_outlined),
  _NavTab(id: 'map', label: 'Carte', icon: Icons.map_outlined),
  _NavTab(id: 'orders', label: 'Commandes', icon: Icons.shopping_bag_outlined),
  _NavTab(id: 'profile', label: 'Profil', icon: Icons.person_outline),
];

const List<_NavTab> _merchantTabs = [
  _NavTab(id: 'baskets', label: 'Paniers', icon: Icons.inventory_2_outlined),
  _NavTab(id: 'orders', label: 'Commandes', icon: Icons.receipt_long_outlined),
  _NavTab(id: 'scan', label: 'Scanner', icon: Icons.qr_code_scanner),
  _NavTab(id: 'profile', label: 'Profil', icon: Icons.person_outline),
];
