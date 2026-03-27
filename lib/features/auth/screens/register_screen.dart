import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:front/features/auth/providers/auth_providers.dart';
import 'package:front/core/providers/storage_providers.dart';
import 'package:front/core/theme/app_theme.dart';

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
  bool _obscurePassword = true;

  String _extractErrorMessage(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final msg = data['message'];
        if (msg is String && msg.trim().isNotEmpty) return msg;
        final errors = data['errors'];
        if (errors is List && errors.isNotEmpty && errors.first is Map<String, dynamic>) {
          final first = errors.first as Map<String, dynamic>;
          final fieldMsg = first['msg'];
          if (fieldMsg is String && fieldMsg.trim().isNotEmpty) return fieldMsg;
        }
      }
    }
    return "Erreur d'inscription. Verifiez les champs.";
  }

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
        await authNotifier.loadUser();
        final isAuthenticated = ref.read(authStateProvider).isAuthenticated;
        if (!isAuthenticated) {
          throw Exception('Session invalide. Veuillez reessayer.');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inscription reussie!')),
        );
        context.go('/home');
      } else {
        throw Exception('Token not found in registration response');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_extractErrorMessage(e))),
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
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/login');
            }
          },
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          children: [
            const SizedBox(height: 8),
            Text(
              'Creer un compte',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 6),
            Text(
              "Rejoignez MealFlavor aujourd'hui",
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Nom complet', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Votre nom',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (val) => val == null || val.isEmpty ? 'Nom requis' : null,
                  ),
                  const SizedBox(height: 16),
                  const Text('Email', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      hintText: 'votre@email.com',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) => val == null || !val.contains('@') ? 'Email invalide' : null,
                  ),
                  const SizedBox(height: 16),
                  const Text('Mot de passe', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      ),
                    ),
                    obscureText: _obscurePassword,
                    validator: (val) => val != null && val.length >= 6 ? null : '6 caracteres minimum',
                  ),
                  const SizedBox(height: 16),
                  const Text('Telephone (optionnel)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      hintText: '+228 90 12 34 56',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 20),
                  const Text('Je suis...', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _roleButton('Client', UserRole.client)),
                      const SizedBox(width: 12),
                      Expanded(child: _roleButton('Commercant', UserRole.merchant)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _register,
                          style: ElevatedButton.styleFrom(
                            shape: const StadiumBorder(),
                          ),
                          child: const Text('Creer mon compte'),
                        ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _roleButton(String label, UserRole role) {
    final isSelected = _selectedRole == role;
    return OutlinedButton(
      onPressed: () => setState(() => _selectedRole = role),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        backgroundColor: isSelected ? AppTheme.primary.withOpacity(0.08) : Colors.white,
        side: BorderSide(color: isSelected ? AppTheme.primary : Colors.grey[300]!),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        label,
        style: TextStyle(color: isSelected ? AppTheme.primary : AppTheme.foreground),
      ),
    );
  }
}
