import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart'; // Add this import
import 'package:front/core/providers/upload_providers.dart'; // Add this import
import 'dart:io'; // Add this import
import 'package:front/features/baskets/providers/basket_providers.dart';
import 'package:front/features/baskets/models/basket_model.dart'; // Import Basket model

class BasketFormScreen extends ConsumerStatefulWidget {
  final String? basketId; // Null for creation, present for editing

  const BasketFormScreen({super.key, this.basketId});

  @override
  ConsumerState<BasketFormScreen> createState() => _BasketFormScreenState();
}

class _BasketFormScreenState extends ConsumerState<BasketFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  String? _selectedCategory; // SWEET, SAVORY, MIXED
  late TextEditingController _originalPriceController;
  late TextEditingController _discountedPriceController;
  late TextEditingController _quantityController;
  late DateTime _pickupTimeStart;
  late DateTime _pickupTimeEnd;
  late TextEditingController _photoURLController;

  bool _isLoading = false;
  Basket? _currentBasket;
  XFile? _imageFile; // Added for picked image

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _originalPriceController = TextEditingController();
    _discountedPriceController = TextEditingController();
    _quantityController = TextEditingController();
    _photoURLController = TextEditingController();
    _pickupTimeStart = DateTime.now();
    _pickupTimeEnd = DateTime.now().add(const Duration(hours: 1));

    if (widget.basketId != null) {
      _loadBasketData(widget.basketId!);
    }
  }

  Future<void> _loadBasketData(String basketId) async {
    setState(() => _isLoading = true);
    try {
      _currentBasket = await ref.read(basketServiceProvider).getBasketDetails(basketId);
      _titleController.text = _currentBasket!.title;
      _descriptionController.text = _currentBasket!.description ?? '';
      _selectedCategory = _currentBasket!.category;
      _originalPriceController.text = _currentBasket!.originalPrice.toString();
      _discountedPriceController.text = _currentBasket!.discountedPrice.toString();
      _quantityController.text = _currentBasket!.quantity.toString();
      _pickupTimeStart = _currentBasket!.pickupTimeStart;
      _pickupTimeEnd = _currentBasket!.pickupTimeEnd;
      _photoURLController.text = _currentBasket!.photoURL ?? '';
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de chargement du panier: ${e.toString()}')),
        );
        context.pop(); // Go back if basket not found or error
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imageFile = image;
      });
    }
  }

  Future<void> _saveBasket() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final basketService = ref.read(basketServiceProvider);
      final uploadService = ref.read(uploadServiceProvider); // Get upload service

      String? photoURL = _photoURLController.text.isEmpty ? null : _photoURLController.text;

      if (_imageFile != null) {
        // Upload image if a new one is selected
        photoURL = await uploadService.uploadImage(_imageFile!);
      }

      if (widget.basketId == null) {
        // Create new basket
        await basketService.createBasket(
          title: _titleController.text,
          description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
          category: _selectedCategory,
          originalPrice: int.parse(_originalPriceController.text),
          discountedPrice: int.parse(_discountedPriceController.text),
          quantity: int.parse(_quantityController.text),
          pickupTimeStart: _pickupTimeStart,
          pickupTimeEnd: _pickupTimeEnd,
          photoURL: photoURL,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Panier créé avec succès!')),
        );
      } else {
        // Update existing basket
        await basketService.updateBasket(
          widget.basketId!,
          title: _titleController.text,
          description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
          category: _selectedCategory,
          originalPrice: int.parse(_originalPriceController.text),
          discountedPrice: int.parse(_discountedPriceController.text),
          quantity: int.parse(_quantityController.text),
          pickupTimeStart: _pickupTimeStart,
          pickupTimeEnd: _pickupTimeEnd,
          photoURL: photoURL,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Panier mis à jour avec succès!')),
        );
      }
      if (mounted) context.pop(); // Go back to dashboard or previous screen
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sauvegarde du panier: ${e.toString()}')),
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
    final bool isEditing = widget.basketId != null;

    if (_isLoading && isEditing) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chargement du panier...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier le Panier' : 'Créer un Panier'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              _buildTextFormField(
                controller: _titleController,
                label: 'Titre du panier',
                validator: (val) => val!.isEmpty ? 'Titre requis' : null,
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _descriptionController,
                label: 'Description du panier',
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Catégorie',
                  border: OutlineInputBorder(),
                ),
                items: ['SWEET', 'SAVORY', 'MIXED']
                    .map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
                validator: (val) => val == null ? 'Catégorie requise' : null,
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _originalPriceController,
                label: 'Prix original (€)',
                keyboardType: TextInputType.number,
                validator: (val) => val!.isEmpty || int.tryParse(val) == null ? 'Prix original requis' : null,
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _discountedPriceController,
                label: 'Prix réduit (€)',
                keyboardType: TextInputType.number,
                validator: (val) => val!.isEmpty || int.tryParse(val) == null ? 'Prix réduit requis' : null,
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _quantityController,
                label: 'Quantité disponible',
                keyboardType: TextInputType.number,
                validator: (val) => val!.isEmpty || int.tryParse(val) == null ? 'Quantité requise' : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text('Heure de début de retrait: ${_pickupTimeStart.toLocal().toString().split(':').sublist(0,2).join(':')}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _pickDateTime(context, true),
              ),
              ListTile(
                title: Text('Heure de fin de retrait: ${_pickupTimeEnd.toLocal().toString().split(':').sublist(0,2).join(':')}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _pickDateTime(context, false),
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Image du panier (facultatif)', style: TextStyle(fontSize: 16)),
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
                                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.shopping_basket, size: 50, color: Colors.grey),
                                  )
                                : const Icon(Icons.shopping_basket, size: 50, color: Colors.grey)),
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
                      onPressed: _saveBasket,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: Text(isEditing ? 'Mettre à jour le panier' : 'Créer le panier'),
                    ),
            ],
          ),
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
    IconData? icon, // Optional icon
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon) : null, // Use icon if provided
        border: const OutlineInputBorder(),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
    );
  }

  Future<void> _pickDateTime(BuildContext context, bool isStart) async {
    final DateTime initial = isStart ? _pickupTimeStart : _pickupTimeEnd;
    final DateTime now = DateTime.now();

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(now) ? now : initial,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (pickedDate == null) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (pickedTime == null) return;

    final DateTime pickedDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    if (!isStart && pickedDateTime.isBefore(_pickupTimeStart)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La fin doit être après le début.')),
        );
      }
      return;
    }

    setState(() {
      if (isStart) {
        _pickupTimeStart = pickedDateTime;
        if (_pickupTimeEnd.isBefore(_pickupTimeStart)) {
          _pickupTimeEnd = _pickupTimeStart.add(const Duration(hours: 1));
        }
      } else {
        _pickupTimeEnd = pickedDateTime;
      }
    });
  }
}
