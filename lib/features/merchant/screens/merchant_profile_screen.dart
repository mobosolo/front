import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart'; // Add this import
import 'package:front/core/providers/upload_providers.dart'; // Add this import
import 'dart:io'; // Add this import
import 'package:front/features/auth/providers/auth_providers.dart';
import 'package:front/features/merchant/models/merchant_model.dart';
import 'package:front/features/merchant/providers/merchant_providers.dart';

class MerchantProfileScreen extends ConsumerStatefulWidget {
  final String? merchantId;

  const MerchantProfileScreen({super.key, this.merchantId});

  @override
  ConsumerState<MerchantProfileScreen> createState() => _MerchantProfileScreenState();
}

class _MerchantProfileScreenState extends ConsumerState<MerchantProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _businessNameController;
  late TextEditingController _typeController;
  late TextEditingController _addressController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;
  late TextEditingController _photoURLController;

  bool _isLoading = false;
  Merchant? _currentMerchant;
  XFile? _imageFile; // Added for picked image

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

    if (!canPrefill) return;

    _businessNameController.text = _currentMerchant!.businessName;
    _typeController.text = _currentMerchant!.type ?? '';
    _addressController.text = _currentMerchant!.address ?? '';
    _phoneNumberController.text = _currentMerchant!.phoneNumber ?? '';
    _latitudeController.text = _currentMerchant!.latitude?.toString() ?? '';
    _longitudeController.text = _currentMerchant!.longitude?.toString() ?? '';
    _photoURLController.text = _currentMerchant!.photoURL ?? '';
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
      final uploadService = ref.read(uploadServiceProvider); // Get upload service

      String? photoURL = _photoURLController.text.isEmpty ? null : _photoURLController.text;

      if (_imageFile != null) {
        // Upload image if a new one is selected
        photoURL = await uploadService.uploadImage(_imageFile!);
      }

      if (widget.merchantId == null) {
        // Register new merchant
        await merchantService.registerMerchant(
          businessName: _businessNameController.text,
          type: _typeController.text.isEmpty ? null : _typeController.text,
          address: _addressController.text.isEmpty ? null : _addressController.text,
          latitude: double.tryParse(_latitudeController.text),
          longitude: double.tryParse(_longitudeController.text),
          phoneNumber: _phoneNumberController.text.isEmpty ? null : _phoneNumberController.text,
          photoURL: photoURL,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil commercant enregistre. En attente de validation.')),
        );
      } else {
        // Update existing merchant
        await merchantService.updateMerchantProfile(
          merchantId: widget.merchantId!,
          businessName: _businessNameController.text,
          type: _typeController.text.isEmpty ? null : _typeController.text,
          address: _addressController.text.isEmpty ? null : _addressController.text,
          latitude: double.tryParse(_latitudeController.text),
          longitude: double.tryParse(_longitudeController.text),
          phoneNumber: _phoneNumberController.text.isEmpty ? null : _phoneNumberController.text,
          photoURL: photoURL,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil commercant mis a jour avec succes!')),
        );
      }

      // After successful registration/update, refresh the user's auth state
      await authNotifier.loadUser();

      // Navigate to the appropriate dashboard
      if (mounted) context.go('/merchant-dashboard');
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
    final isEditing = widget.merchantId != null || _currentMerchant != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier votre commerce' : 'Devenir commercant'),
        leading: isEditing
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              )
            : null,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            Text(
              isEditing
                  ? 'Mettez a jour les informations de votre commerce'
                  : 'Enregistrez votre commerce',
              style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Renseignez les informations de votre etablissement pour publier des paniers.',
              style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTextFormField(
                    controller: _businessNameController,
                    label: 'Nom du commerce',
                    icon: Icons.store,
                    validator: (val) => val!.isEmpty ? 'Nom du commerce requis' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextFormField(
                    controller: _typeController,
                    label: 'Type de commerce (ex: Boulangerie, Restaurant)',
                    icon: Icons.category,
                  ),
                  const SizedBox(height: 16),
                  _buildTextFormField(
                    controller: _addressController,
                    label: 'Adresse physique',
                    icon: Icons.location_on,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextFormField(
                          controller: _latitudeController,
                          label: 'Latitude',
                          icon: Icons.map,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextFormField(
                          controller: _longitudeController,
                          label: 'Longitude',
                          icon: Icons.map,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                                    _buildTextFormField(
                                      controller: _phoneNumberController,
                                      label: 'Telephone du commerce',
                                      icon: Icons.phone,
                                      keyboardType: TextInputType.phone,
                                    ),
                                    const SizedBox(height: 16),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Image du commerce (facultatif)', style: TextStyle(fontSize: 16)),
                                        const SizedBox(height: 8),
                                        Center(
                                          child: GestureDetector(
                                            onTap: _pickImage,
                                            child: Container(
                                              height: 150,
                                              width: 150,
                                              decoration: BoxDecoration(
                                                color: Colors.grey[200],
                                                borderRadius: BorderRadius.circular(8.0),
                                                border: Border.all(color: Colors.grey),
                                              ),
                                              child: _imageFile != null
                                                  ? Image.file(
                                                      File(_imageFile!.path),
                                                      fit: BoxFit.cover,
                                                    )
                                                  : (_photoURLController.text.isNotEmpty
                                                      ? Image.network(
                                                          _photoURLController.text,
                                                          fit: BoxFit.cover,
                                                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.store, size: 50, color: Colors.grey),
                                                        )
                                                      : const Icon(Icons.store, size: 50, color: Colors.grey)),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Center(
                                          child: ElevatedButton(
                                            onPressed: _pickImage,
                                            child: const Text('Choisir une image'),
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    const SizedBox(height: 32),
                  
                                    _isLoading
                                        ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _saveMerchantProfile,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          child: Text(isEditing ? 'Mettre a jour le profil' : 'Enregistrer mon commerce'),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    int? maxLines,
    String? Function(String?)? validator,
    IconData? icon,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon) : null,
        border: const OutlineInputBorder(),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
    );
  }
}
