import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:front/core/theme/app_theme.dart';

class AdminBottomNav extends StatelessWidget {
  final String activeTab;

  const AdminBottomNav({super.key, required this.activeTab});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      padding: const EdgeInsets.only(bottom: 8),
      height: 64,
      child: Row(
        children: _tabs.map((tab) {
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
    );
  }

  void _navigate(BuildContext context, String tabId) {
    switch (tabId) {
      case 'dashboard':
        context.go('/admin-dashboard');
        return;
      case 'merchants':
        context.go('/admin-merchants');
        return;
      case 'users':
        context.go('/admin-users');
        return;
    }
  }
}

class _NavTab {
  final String id;
  final String label;
  final IconData icon;

  const _NavTab({required this.id, required this.label, required this.icon});
}

const List<_NavTab> _tabs = [
  _NavTab(id: 'dashboard', label: 'Dashboard', icon: Icons.dashboard_outlined),
  _NavTab(id: 'merchants', label: 'Commercants', icon: Icons.store_outlined),
  _NavTab(id: 'users', label: 'Utilisateurs', icon: Icons.group_outlined),
];
