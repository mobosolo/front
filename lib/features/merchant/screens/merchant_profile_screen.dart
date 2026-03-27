import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:front/core/providers/upload_providers.dart';
import 'package:front/core/providers/storage_providers.dart';
import 'package:front/core/theme/app_theme.dart';
import 'package:front/core/widgets/bottom_nav.dart';
import 'package:front/features/auth/providers/auth_providers.dart';
import 'package:front/features/merchant/models/merchant_model.dart';
import 'package:front/features/merchant/providers/merchant_providers.dart';
import 'package:front/features/notifications/providers/app_notification_providers.dart';
import 'package:front/core/utils/route_refresh_mixin.dart';

class MerchantProfileScreen extends ConsumerStatefulWidget {
  final String? merchantId;

  const MerchantProfileScreen({super.key, this.merchantId});

  @override
  ConsumerState<MerchantProfileScreen> createState() => _MerchantProfileScreenState();
}

class _MerchantProfileScreenState extends ConsumerState<MerchantProfileScreen> with RouteRefreshMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _businessNameController;
  late TextEditingController _typeController;
  late TextEditingController _addressController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;
  late TextEditingController _photoURLController;

  bool _isLoading = false;
  bool _isEditing = false;
  Merchant? _currentMerchant;
  XFile? _imageFile;

  @override
  void initState() {
    super.initState();
    _businessNameController = TextEditingController();
    _typeController = TextEditingController();
    _addressController = TextEditingController();
    _phoneNumberController = TextEditingController();
    _latitudeController = TextEditingController();
    _longitudeController = TextEditingController();
    _photoURLController = TextEditingController();
    _loadMerchantData();
  }

  @override
  void onRouteResumed() {
    _loadMerchantData();
  }

  Future<void> _loadMerchantData() async {
    final authState = ref.read(authStateProvider);
    _currentMerchant = authState.user?.merchant;

    if (_currentMerchant == null) {
      try {
        final merchantService = ref.read(merchantServiceProvider);
        _currentMerchant = await merchantService.getMyMerchantProfile();
      } catch (_) {
        // No merchant profile yet.
      }
    }

    final canPrefill = _currentMerchant != null &&
        (widget.merchantId == null || _currentMerchant!.id == widget.merchantId);

    if (!canPrefill) {
      if (mounted) {
        setState(() => _isEditing = true);
      }
      return;
    }

    _businessNameController.text = _currentMerchant!.businessName;
    _typeController.text = _currentMerchant!.type ?? '';
    _addressController.text = _currentMerchant!.address ?? '';
    _phoneNumberController.text = _currentMerchant!.phoneNumber ?? '';
    _latitudeController.text = _currentMerchant!.latitude?.toString() ?? '';
    _longitudeController.text = _currentMerchant!.longitude?.toString() ?? '';
    _photoURLController.text = _currentMerchant!.photoURL ?? '';

    if (mounted) {
      setState(() => _isEditing = _currentMerchant == null);
    }
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _typeController.dispose();
    _addressController.dispose();
    _phoneNumberController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _photoURLController.dispose();
    super.dispose();
  }

  void _resetForm() {
    if (_currentMerchant == null) {
      _businessNameController.clear();
      _typeController.clear();
      _addressController.clear();
      _phoneNumberController.clear();
      _latitudeController.clear();
      _longitudeController.clear();
      _photoURLController.clear();
      setState(() => _imageFile = null);
      return;
    }

    _businessNameController.text = _currentMerchant!.businessName;
    _typeController.text = _currentMerchant!.type ?? '';
    _addressController.text = _currentMerchant!.address ?? '';
    _phoneNumberController.text = _currentMerchant!.phoneNumber ?? '';
    _latitudeController.text = _currentMerchant!.latitude?.toString() ?? '';
    _longitudeController.text = _currentMerchant!.longitude?.toString() ?? '';
    _photoURLController.text = _currentMerchant!.photoURL ?? '';
    setState(() => _imageFile = null);
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imageFile = image;
      });
    }
  }

  Future<void> _saveMerchantProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final merchantService = ref.read(merchantServiceProvider);
      final authNotifier = ref.read(authStateProvider.notifier);
      final uploadService = ref.read(uploadServiceProvider);

      String? photoURL = _photoURLController.text.isEmpty ? null : _photoURLController.text;

      if (_imageFile != null) {
        photoURL = await uploadService.uploadImage(_imageFile!);
      }

      final String? resolvedMerchantId = widget.merchantId ?? _currentMerchant?.id;

      if (resolvedMerchantId == null) {
        await merchantService.registerMerchant(
          businessName: _businessNameController.text,
          type: _typeController.text.isEmpty ? null : _typeController.text,
          address: _addressController.text.isEmpty ? null : _addressController.text,
          latitude: double.tryParse(_latitudeController.text),
          longitude: double.tryParse(_longitudeController.text),
          phoneNumber: _phoneNumberController.text.isEmpty ? null : _phoneNumberController.text,
          photoURL: photoURL,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profil commercant enregistre. En attente de validation.')),
          );
        }
      } else {
        await merchantService.updateMerchantProfile(
          merchantId: resolvedMerchantId,
          businessName: _businessNameController.text,
          type: _typeController.text.isEmpty ? null : _typeController.text,
          address: _addressController.text.isEmpty ? null : _addressController.text,
          latitude: double.tryParse(_latitudeController.text),
          longitude: double.tryParse(_longitudeController.text),
          phoneNumber: _phoneNumberController.text.isEmpty ? null : _phoneNumberController.text,
          photoURL: photoURL,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profil commercant mis a jour avec succes!')),
          );
        }
      }

      await authNotifier.loadUser();

      if (mounted) {
        setState(() => _isEditing = false);
        context.go('/merchant-dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sauvegarde du profil commercant: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool hasMerchant = _currentMerchant != null;
    final String displayName = _businessNameController.text.isNotEmpty
        ? _businessNameController.text
        : (_currentMerchant?.businessName ?? 'Commerce');
    final String displayType = _typeController.text.isNotEmpty
        ? _typeController.text
        : (_currentMerchant?.type ?? 'Commerce');

    return Scaffold(
      backgroundColor: AppTheme.background,
      bottomNavigationBar: const BottomNav(activeTab: 'profile', role: 'MERCHANT'),
      body: SafeArea(
        child: ListView(
          children: [
            _header(context, displayName, displayType),
            _notificationsShortcut(context),
            _statsShortcut(context),
            _detailsSection(context, theme, hasMerchant),
            _logout(context, ref),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _notificationsShortcut(BuildContext context) {
    final service = ref.read(appNotificationServiceProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: InkWell(
          onTap: () => context.push('/notifications'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.notifications_outlined, color: AppTheme.mutedForeground),
                const SizedBox(width: 12),
                const Expanded(child: Text('Notifications')),
                FutureBuilder(
                  future: service.getNotifications(limit: 100, offset: 0),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox.shrink();
                    final unread = snapshot.data!.where((n) => !n.isRead).length;
                    if (unread == 0) return const SizedBox.shrink();
                    final label = unread > 99 ? '99+' : unread.toString();
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        label,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    );
                  },
                ),
                Icon(Icons.chevron_right, color: Colors.grey[500]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statsShortcut(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: InkWell(
          onTap: () => context.push('/merchant-dashboard'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.bar_chart_outlined, color: AppTheme.mutedForeground),
                const SizedBox(width: 12),
                const Expanded(child: Text('Statistiques')),
                Icon(Icons.chevron_right, color: Colors.grey[500]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, String name, String type) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Profil Commerce', style: Theme.of(context).textTheme.headlineMedium),
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
                  child: const Icon(Icons.store, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 12),
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(type, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailsSection(BuildContext context, ThemeData theme, bool hasMerchant) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Informations du commerce', style: theme.textTheme.titleMedium),
              if (!_isEditing)
                TextButton(
                  onPressed: () => setState(() => _isEditing = true),
                  child: const Text('Modifier'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Form(
            key: _formKey,
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
                  _detailRow(
                    icon: Icons.store,
                    label: 'Nom du commerce',
                    value: _currentMerchant?.businessName ?? '',
                    controller: _businessNameController,
                    validator: (val) => val!.isEmpty ? 'Nom du commerce requis' : null,
                  ),
                  _detailRow(
                    icon: Icons.location_on_outlined,
                    label: 'Adresse',
                    value: _currentMerchant?.address ?? '',
                    controller: _addressController,
                    hasBorder: true,
                  ),
                  _detailRow(
                    icon: Icons.phone_outlined,
                    label: 'Telephone',
                    value: _currentMerchant?.phoneNumber ?? '',
                    controller: _phoneNumberController,
                    keyboardType: TextInputType.phone,
                    hasBorder: true,
                  ),
                  _detailRow(
                    icon: Icons.category_outlined,
                    label: 'Type de commerce',
                    value: _currentMerchant?.type ?? '',
                    controller: _typeController,
                    hasBorder: false,
                  ),
                  if (_isEditing || _photoURLController.text.isNotEmpty)
                    _imagePickerRow(),
                ],
              ),
            ),
          ),
          if (_isEditing) ...[
            const SizedBox(height: 16),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveMerchantProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: const StadiumBorder(),
                          ),
                          child: Text(hasMerchant ? 'Enregistrer modifications' : 'Enregistrer mon commerce'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() => _isEditing = false);
                            _resetForm();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.mutedForeground,
                            side: BorderSide.none,
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Annuler'),
                        ),
                      ),
                    ],
                  ),
          ],
        ],
      ),
    );
  }

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
    required TextEditingController controller,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool hasBorder = true,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: hasBorder ? const Border(bottom: BorderSide(color: AppTheme.border)) : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.mutedForeground),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.mutedForeground)),
                const SizedBox(height: 6),
                if (_isEditing)
                  TextFormField(
                    controller: controller,
                    keyboardType: keyboardType,
                    validator: validator,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppTheme.muted,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  )
                else
                  Text(value.isNotEmpty ? value : '-'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePickerRow() {
    final String photoUrl = _photoURLController.text;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Image du commerce', style: TextStyle(fontSize: 12, color: AppTheme.mutedForeground)),
          const SizedBox(height: 12),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 72,
                  height: 72,
                  color: AppTheme.muted,
                  child: _imageFile != null
                      ? FutureBuilder<Uint8List>(
                          future: _imageFile!.readAsBytes(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Image.memory(snapshot.data!, fit: BoxFit.cover);
                            }
                            if (snapshot.hasError) {
                              return const Icon(Icons.broken_image, color: AppTheme.mutedForeground);
                            }
                            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                          },
                        )
                      : (photoUrl.isNotEmpty
                          ? Image.network(
                              photoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.store, color: AppTheme.mutedForeground),
                            )
                          : const Icon(Icons.store, color: AppTheme.mutedForeground)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton(
                  onPressed: _pickImage,
                  style: OutlinedButton.styleFrom(
                    shape: const StadiumBorder(),
                    side: BorderSide(color: AppTheme.border),
                  ),
                  child: const Text('Choisir une image'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _logout(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 4),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () async {
            await ref.read(tokenStorageServiceProvider).deleteToken();
            ref.read(authStateProvider.notifier).logout();
            if (context.mounted) context.go('/login');
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
