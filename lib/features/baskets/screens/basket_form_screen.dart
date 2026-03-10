import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front/core/providers/upload_providers.dart';
import 'package:front/core/theme/app_theme.dart';
import 'package:front/features/baskets/models/basket_model.dart';
import 'package:front/features/baskets/providers/basket_providers.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class BasketFormScreen extends ConsumerStatefulWidget {
  final String? basketId;

  const BasketFormScreen({super.key, this.basketId});

  @override
  ConsumerState<BasketFormScreen> createState() => _BasketFormScreenState();
}

class _BasketFormScreenState extends ConsumerState<BasketFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _originalPriceController;
  late TextEditingController _discountedPriceController;
  late TextEditingController _quantityController;
  late DateTime _pickupTimeStart;
  late DateTime _pickupTimeEnd;
  late TextEditingController _photoURLController;

  bool _isLoading = false;
  Basket? _currentBasket;
  XFile? _imageFile;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _originalPriceController = TextEditingController();
    _discountedPriceController = TextEditingController();
    _quantityController = TextEditingController(text: '1');
    _photoURLController = TextEditingController();
    _pickupTimeStart = DateTime.now().add(const Duration(hours: 1));
    _pickupTimeEnd = DateTime.now().add(const Duration(hours: 3));

    if (widget.basketId != null) {
      _loadBasketData(widget.basketId!);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _originalPriceController.dispose();
    _discountedPriceController.dispose();
    _quantityController.dispose();
    _photoURLController.dispose();
    super.dispose();
  }

  Future<void> _loadBasketData(String basketId) async {
    setState(() => _isLoading = true);
    try {
      _currentBasket = await ref.read(basketServiceProvider).getBasketDetails(basketId);
      _titleController.text = _currentBasket!.title;
      _descriptionController.text = _currentBasket!.description ?? '';
      _originalPriceController.text = _currentBasket!.originalPrice.toString();
      _discountedPriceController.text = _currentBasket!.discountedPrice.toString();
      _quantityController.text = _currentBasket!.quantity.toString();
      _pickupTimeStart = _currentBasket!.pickupTimeStart;
      _pickupTimeEnd = _currentBasket!.pickupTimeEnd;
      _photoURLController.text = _currentBasket!.photoURL ?? '';
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de chargement du panier: ${_extractErrorMessage(e)}')),
      );
      context.pop();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      setState(() {
        _imageFile = picked;
      });
    }
  }

  Future<void> _saveBasket() async {
    if (!_formKey.currentState!.validate()) return;

    final isCreate = widget.basketId == null;
    if (isCreate && _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("L'image du panier est obligatoire.")),
      );
      return;
    }

    if (_pickupTimeEnd.isBefore(_pickupTimeStart) || _pickupTimeEnd.isAtSameMomentAs(_pickupTimeStart)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('L heure de fin doit etre apres l heure de debut.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final basketService = ref.read(basketServiceProvider);
      final uploadService = ref.read(uploadServiceProvider);

      String? photoURL = _photoURLController.text.trim().isEmpty ? null : _photoURLController.text.trim();
      if (_imageFile != null) {
        photoURL = await uploadService.uploadImage(_imageFile!);
      }

      if (isCreate) {
        await basketService.createBasket(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          category: 'MIXED',
          originalPrice: int.parse(_originalPriceController.text),
          discountedPrice: int.parse(_discountedPriceController.text),
          quantity: int.parse(_quantityController.text),
          pickupTimeStart: _pickupTimeStart,
          pickupTimeEnd: _pickupTimeEnd,
          photoURL: photoURL,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Panier cree avec succes!')),
        );
      } else {
        await basketService.updateBasket(
          widget.basketId!,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          category: 'MIXED',
          originalPrice: int.parse(_originalPriceController.text),
          discountedPrice: int.parse(_discountedPriceController.text),
          quantity: int.parse(_quantityController.text),
          pickupTimeStart: _pickupTimeStart,
          pickupTimeEnd: _pickupTimeEnd,
          photoURL: photoURL,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Panier mis a jour avec succes!')),
        );
      }

      if (mounted) context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sauvegarde: ${_extractErrorMessage(e)}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _extractErrorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final list = data['errors'];
        if (list is List && list.isNotEmpty) {
          final first = list.first;
          if (first is Map<String, dynamic>) {
            final msg = first['msg']?.toString();
            if (msg != null && msg.isNotEmpty) return msg;
          }
        }
        final message = data['message']?.toString();
        final backendError = data['error']?.toString();
        if (message != null && message.isNotEmpty) return message;
        if (backendError != null && backendError.isNotEmpty) return backendError;
      }
      return error.message ?? 'Erreur reseau';
    }
    return error.toString();
  }

  Future<void> _pickTime(bool isStart) async {
    final source = isStart ? _pickupTimeStart : _pickupTimeEnd;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(source),
    );
    if (picked == null) return;

    setState(() {
      final updated = DateTime(
        source.year,
        source.month,
        source.day,
        picked.hour,
        picked.minute,
      );
      if (isStart) {
        _pickupTimeStart = updated;
      } else {
        _pickupTimeEnd = updated;
      }
    });
  }

  String _hhmm(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.basketId != null;

    if (_isLoading && isEditing && _currentBasket == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(isEditing ? 'Modifier un panier' : 'Creer un panier'),
        backgroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          children: [
            Text('Photo du panier', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 160,
                decoration: BoxDecoration(
                  color: AppTheme.muted,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.border),
                ),
                child: _imageFile != null
                    ? FutureBuilder<Uint8List>(
                        future: _imageFile!.readAsBytes(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.memory(snapshot.data!, fit: BoxFit.cover),
                            );
                          }
                          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                        },
                      )
                    : (_photoURLController.text.trim().isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.network(
                              _photoURLController.text.trim(),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => _photoPlaceholder(),
                            ),
                          )
                        : _photoPlaceholder()),
              ),
            ),
            const SizedBox(height: 18),
            _fieldLabel('Titre du panier'),
            const SizedBox(height: 8),
            _input(
              controller: _titleController,
              hint: 'Ex: Panier Boulangerie du Jour',
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Titre requis' : null,
            ),
            _fieldLabel('Description'),
            const SizedBox(height: 8),
            _input(
              controller: _descriptionController,
              hint: 'Decrivez le contenu du panier...',
              maxLines: 4,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Description requise' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fieldLabel('Prix original (F)'),
                      const SizedBox(height: 8),
                      _input(
                        controller: _originalPriceController,
                        hint: '3000',
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          final parsed = int.tryParse(v ?? '');
                          if (parsed == null || parsed <= 0) return 'Invalide';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fieldLabel('Prix reduit (F)'),
                      const SizedBox(height: 8),
                      _input(
                        controller: _discountedPriceController,
                        hint: '1000',
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          final parsed = int.tryParse(v ?? '');
                          if (parsed == null || parsed <= 0) return 'Invalide';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _fieldLabel('Quantite disponible'),
            const SizedBox(height: 8),
            _input(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              validator: (v) {
                final parsed = int.tryParse(v ?? '');
                if (parsed == null || parsed <= 0) return 'Quantite invalide';
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _timeInput(
                    label: 'Heure de debut',
                    value: _hhmm(_pickupTimeStart),
                    onTap: () => _pickTime(true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _timeInput(
                    label: 'Heure de fin',
                    value: _hhmm(_pickupTimeEnd),
                    onTap: () => _pickTime(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveBasket,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(isEditing ? 'Mettre a jour panier' : 'Publier panier'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoPlaceholder() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.camera_alt_outlined, size: 34, color: AppTheme.mutedForeground),
          SizedBox(height: 8),
          Text('Prendre une photo', style: TextStyle(color: AppTheme.mutedForeground)),
          SizedBox(height: 2),
          Text('ou choisir depuis la galerie', style: TextStyle(fontSize: 12, color: AppTheme.mutedForeground)),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.border),
        ),
      ),
    );
  }

  Widget _timeInput({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, size: 18, color: AppTheme.mutedForeground),
                const SizedBox(width: 8),
                Text(value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
