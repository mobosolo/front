import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:front/core/theme/app_theme.dart';
import 'package:front/core/providers/storage_providers.dart';
import 'package:front/features/auth/providers/auth_providers.dart';
import 'package:front/core/widgets/admin_bottom_nav.dart';
import 'package:front/features/admin/models/admin_models.dart';
import 'package:front/features/admin/providers/admin_providers.dart';

class AdminMerchantsScreen extends ConsumerStatefulWidget {
  const AdminMerchantsScreen({super.key});

  @override
  ConsumerState<AdminMerchantsScreen> createState() => _AdminMerchantsScreenState();
}

class _AdminMerchantsScreenState extends ConsumerState<AdminMerchantsScreen> {
  List<AdminMerchant> _merchants = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _status = 'PENDING';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final adminService = ref.read(adminServiceProvider);
      final merchants = await adminService.getMerchants(status: _status);
      if (!mounted) return;
      setState(() => _merchants = merchants);
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
      bottomNavigationBar: const AdminBottomNav(activeTab: 'merchants'),
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
              else if (_merchants.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12),
                  child: _emptyState(),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    children: _merchants.map(_merchantCard).toList(),
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
              Text('Commercants', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white)),
              _logoutButton(),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Gestion des demandes et statuts',
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
          _filterChip('PENDING', 'En attente'),
          const SizedBox(width: 8),
          _filterChip('APPROVED', 'Approuves'),
          const SizedBox(width: 8),
          _filterChip('REJECTED', 'Rejetes'),
        ],
      ),
    );
  }

  Widget _filterChip(String value, String label) {
    final bool selected = _status == value;
    return InkWell(
      onTap: () {
        setState(() => _status = value);
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
          Row(
            children: [
              Expanded(
                child: Text(merchant.businessName, style: Theme.of(context).textTheme.titleMedium),
              ),
              _statusPill(merchant.status),
            ],
          ),
          const SizedBox(height: 6),
          if ((merchant.userEmail ?? '').isNotEmpty)
            Text(
              merchant.userEmail!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.mutedForeground),
            ),
          const SizedBox(height: 6),
          Text(
            merchant.address ?? 'Adresse inconnue',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.mutedForeground),
          ),
          const SizedBox(height: 12),
          if (_status == 'PENDING')
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
            )
          else
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                _statusLabel(merchant.status),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.mutedForeground),
              ),
            ),
        ],
      ),
    );
  }

  Widget _statusPill(String status) {
    final color = status == 'APPROVED'
        ? AppTheme.success
        : status == 'REJECTED'
            ? AppTheme.destructive
            : AppTheme.secondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'APPROVED':
        return 'Approuve';
      case 'REJECTED':
        return 'Rejete';
      default:
        return 'En attente';
    }
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
              'Aucun commerce dans cette categorie.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
