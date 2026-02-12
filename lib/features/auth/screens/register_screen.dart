import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:front/features/auth/providers/auth_providers.dart';
import 'package:front/core/providers/storage_providers.dart';

enum UserRole { client, merchant }

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  UserRole _selectedRole = UserRole.client;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authNotifier = ref.read(authStateProvider.notifier);
      final tokenStorageService = ref.read(tokenStorageServiceProvider);
      final authService = ref.read(authServiceProvider);
      
      final roleString = _selectedRole == UserRole.client ? 'CLIENT' : 'MERCHANT';

      // Assuming the register endpoint also returns a token
      final result = await authService.register(
        _nameController.text,
        _emailController.text,
        _passwordController.text,
        _phoneController.text,
        roleString,
      );

      final token = result['token'];
      if (token != null) {
        await tokenStorageService.saveToken(token);
        await authNotifier.loadUser(); // This will update the state

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inscription réussie!')),
        );
        context.go('/home');
      } else {
        throw Exception('Token not found in registration response');
      }

    } catch (e) {
      if (mounted) { // Add mounted check
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur d'inscription: ${e.toString()}")),
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

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          children: [
            const SizedBox(height: 20),
            Text(
              'Créer un compte',
              style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Rejoignez MealFlavor aujourd\'hui',
              style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Form Fields
                  _buildTextFormField(controller: _nameController, label: 'Nom complet', icon: Icons.person_outline, validator: (val) => val!.isEmpty ? 'Nom requis' : null),
                  const SizedBox(height: 16),
                  _buildTextFormField(controller: _emailController, label: 'Email', icon: Icons.mail_outline, keyboardType: TextInputType.emailAddress, validator: (val) => val!.isEmpty || !val.contains('@') ? 'Email invalide' : null),
                  const SizedBox(height: 16),
                  _buildTextFormField(controller: _passwordController, label: 'Mot de passe', icon: Icons.lock_outline, obscureText: true, validator: (val) => val!.length < 6 ? '6 caractères minimum' : null),
                  const SizedBox(height: 16),
                  _buildTextFormField(controller: _phoneController, label: 'Téléphone', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
                  
                  const SizedBox(height: 24),
                  
                  // Role Selector
                  Text('Je suis...', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildRoleButton(context, 'Client', UserRole.client),
                      const SizedBox(width: 16),
                      _buildRoleButton(context, 'Commerçant', UserRole.merchant),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Submit Button
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _register,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          child: const Text('Créer mon compte'),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField({required TextEditingController controller, required String label, required IconData icon, bool obscureText = false, TextInputType? keyboardType, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildRoleButton(BuildContext context, String title, UserRole role) {
    final isSelected = _selectedRole == role;
    final theme = Theme.of(context);
    
    return Expanded(
      child: OutlinedButton(
        onPressed: () => setState(() => _selectedRole = role),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: isSelected ? theme.colorScheme.primary.withOpacity(0.1) : null,
          side: BorderSide(color: isSelected ? theme.colorScheme.primary : Colors.grey[400]!),
        ),
        child: Text(title, style: TextStyle(color: isSelected ? theme.colorScheme.primary : theme.textTheme.bodyLarge?.color)),
      ),
    );
  }
}
