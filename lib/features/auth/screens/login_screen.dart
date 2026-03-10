import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:front/features/auth/providers/auth_providers.dart';
import 'package:front/core/providers/storage_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        final authNotifier = ref.read(authStateProvider.notifier);
        final tokenStorageService = ref.read(tokenStorageServiceProvider);
        final authService = ref.read(authServiceProvider);

        final result = await authService.login(
          _emailController.text,
          _passwordController.text,
        );

        final token = result['token'];
        if (token != null) {
          await tokenStorageService.saveToken(token);
          await authNotifier.loadUser();
          final isAuthenticated = ref.read(authStateProvider).isAuthenticated;
          if (!isAuthenticated) {
            throw Exception('Session invalide. Veuillez réessayer.');
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Connexion réussie!')),
          );
          context.go('/home');
        } else {
          throw Exception('Token not found in response');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur de connexion: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
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
              context.go('/onboarding');
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
              'Connexion',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'Accédez à votre compte MealFlavor',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Email', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      hintText: 'votre@email.com',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty || !value.contains('@')) {
                        return 'Veuillez entrer un email valide';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Mot de passe', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      hintText: '••••••••',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer votre mot de passe';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => context.push('/forgot-password'),
                      child: const Text('Mot de passe oublié ?'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            shape: const StadiumBorder(),
                          ),
                          child: const Text('Connexion'),
                        ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Column(
              children: [
                Text(
                  'Pas encore de compte ?',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
                TextButton(
                  onPressed: () => context.go('/register'),
                  child: const Text('Créer un compte'),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
