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

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> with RouteRefreshMixin {
  AdminStats? _stats;
  List<AdminMerchant> _pending = [];
  bool _isLoading = true;
  String? _errorMessage;

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
      final stats = await adminService.getAdminStats();
      final pending = await adminService.getMerchants(status: 'PENDING');
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _pending = pending;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Erreur lors du chargement: ${e.toString()}';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _approve(AdminMerchant merchant) async {
    final adminService = ref.read(adminServiceProvider);
    try {
      await adminService.approveMerchant(merchant.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Commerce approuve.')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    }
  }

  Future<void> _reject(AdminMerchant merchant) async {
    final adminService = ref.read(adminServiceProvider);
    try {
      await adminService.rejectMerchant(merchant.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Commerce rejete.')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      bottomNavigationBar: const AdminBottomNav(activeTab: 'dashboard'),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(),
                const SizedBox(height: 16),
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
                else ...[
                  _statsGrid(),
                  const SizedBox(height: 24),
                  _pendingSection(),
                ],
                const SizedBox(height: 32),
              ],
            ),
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
              Text('Admin Center', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white)),
              _logoutButton(),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Vue globale des activites',
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

  Widget _statsGrid() {
    final stats = _stats;
    if (stats == null) return const SizedBox.shrink();

    final items = [
      _StatItem('Utilisateurs', stats.totalUsers, Icons.group_outlined, AppTheme.primary),
      _StatItem('Commercants', stats.totalMerchants, Icons.store_outlined, AppTheme.secondary),
      _StatItem('En attente', stats.pendingMerchants, Icons.hourglass_empty, AppTheme.destructive),
      _StatItem('Paniers', stats.totalBaskets, Icons.shopping_basket_outlined, AppTheme.primary),
      _StatItem('Commandes', stats.totalOrders, Icons.receipt_long_outlined, AppTheme.secondary),
      _StatItem('Retires', stats.pickedUpOrders, Icons.check_circle_outline, AppTheme.success),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: items.map((item) => _statCard(item)).toList(),
      ),
    );
  }

  Widget _statCard(_StatItem item) {
    final width = (MediaQuery.of(context).size.width - 20 * 2 - 12) / 2;
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
        boxShadow: const [
          BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: item.color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            item.label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.mutedForeground),
          ),
          const SizedBox(height: 4),
          Text(
            item.value.toString(),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _pendingSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Commercants en attente', style: Theme.of(context).textTheme.titleMedium),
              TextButton(
                onPressed: () => context.go('/admin-merchants'),
                child: const Text('Tout voir'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_pending.isEmpty)
            _emptyState()
          else
            Column(
              children: _pending.take(4).map(_merchantCard).toList(),
            ),
        ],
      ),
    );
  }

  Widget _merchantCard(AdminMerchant merchant) {
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
          Text(merchant.businessName, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            merchant.address ?? 'Adresse inconnue',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.mutedForeground),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _reject(merchant),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.destructive,
                    side: const BorderSide(color: AppTheme.destructive),
                  ),
                  child: const Text('Rejeter'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _approve(merchant),
                  child: const Text('Approuver'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
          const Icon(Icons.check_circle_outline, color: AppTheme.success),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Aucun commerce en attente pour le moment.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  _StatItem(this.label, this.value, this.icon, this.color);
}
