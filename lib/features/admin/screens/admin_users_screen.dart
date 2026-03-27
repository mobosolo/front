import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:front/core/theme/app_theme.dart';
import 'package:front/core/providers/storage_providers.dart';
import 'package:front/features/auth/providers/auth_providers.dart';
import 'package:front/core/widgets/admin_bottom_nav.dart';
import 'package:front/features/admin/models/admin_models.dart';
import 'package:front/features/admin/providers/admin_providers.dart';
import 'package:front/core/utils/route_refresh_mixin.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> with RouteRefreshMixin {
  List<AdminUser> _users = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _role = 'ALL';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void onRouteResumed() {
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final adminService = ref.read(adminServiceProvider);
      final roleFilter = _role == 'ALL' ? null : _role;
      final users = await adminService.getUsers(role: roleFilter);
      if (!mounted) return;
      setState(() => _users = users);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Erreur lors du chargement: ${e.toString()}';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      bottomNavigationBar: const AdminBottomNav(activeTab: 'users'),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            children: [
              _header(),
              const SizedBox(height: 16),
              _filters(),
              const SizedBox(height: 8),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(_errorMessage!),
                )
              else if (_users.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12),
                  child: _emptyState(),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    children: _users.map(_userCard).toList(),
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x26000000), blurRadius: 20, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Utilisateurs', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white)),
              _logoutButton(),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Vue globale des comptes',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white.withOpacity(0.9)),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _logoutButton() {
    return Consumer(
      builder: (context, ref, _) {
        return IconButton(
          onPressed: () async {
            await ref.read(tokenStorageServiceProvider).deleteToken();
            ref.read(authStateProvider.notifier).logout();
            if (context.mounted) context.go('/login');
          },
          icon: const Icon(Icons.logout, color: Colors.white),
          tooltip: 'Deconnexion',
        );
      },
    );
  }

  Widget _filters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          _filterChip('ALL', 'Tous'),
          const SizedBox(width: 8),
          _filterChip('CLIENT', 'Clients'),
          const SizedBox(width: 8),
          _filterChip('MERCHANT', 'Commercants'),
          const SizedBox(width: 8),
          _filterChip('ADMIN', 'Admins'),
        ],
      ),
    );
  }

  Widget _filterChip(String value, String label) {
    final bool selected = _role == value;
    return InkWell(
      onTap: () {
        setState(() => _role = value);
        _load();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? AppTheme.primary : AppTheme.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppTheme.mutedForeground,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _userCard(AdminUser user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(user.displayName ?? user.email, style: Theme.of(context).textTheme.titleMedium),
              ),
              _rolePill(user.role),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            user.email,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.mutedForeground),
          ),
          if ((user.phoneNumber ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              user.phoneNumber!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.mutedForeground),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            _formatDate(user.createdAt),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.mutedForeground),
          ),
        ],
      ),
    );
  }

  Widget _rolePill(String role) {
    final color = role == 'ADMIN'
        ? AppTheme.destructive
        : role == 'MERCHANT'
            ? AppTheme.secondary
            : AppTheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _roleLabel(role),
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'ADMIN':
        return 'Admin';
      case 'MERCHANT':
        return 'Commercant';
      default:
        return 'Client';
    }
  }

  String _formatDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    return 'Cree le $d/$m/$y';
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.people_outline, color: AppTheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Aucun utilisateur dans cette categorie.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
