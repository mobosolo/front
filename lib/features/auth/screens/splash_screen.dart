import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:front/features/auth/providers/auth_providers.dart';
import 'package:front/core/providers/storage_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Wait a bit to show splash screen
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    final tokenStorage = ref.read(tokenStorageServiceProvider);
    final token = await tokenStorage.getToken();

    if (token == null || token.isEmpty) {
      if (!mounted) return;
      context.go('/login');
      return;
    }

    if (!mounted) return;
    await ref.read(authStateProvider.notifier).loadUser();

    if (!mounted) return;
    final isAuthenticated = ref.read(authStateProvider).isAuthenticated;

    if (mounted) {
      if (isAuthenticated) {
        context.go('/home');
      } else {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
