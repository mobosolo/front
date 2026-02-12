import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:front/features/auth/providers/auth_providers.dart';
import 'package:front/core/providers/storage_providers.dart';

class MerchantDashboardScreen extends ConsumerWidget {
  const MerchantDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final merchantStatus = authState.user?.merchant?.status;
    final canCreateBasket = merchantStatus == 'APPROVED';

    void onCreateBasketPressed() {
      if (canCreateBasket) {
        context.push('/create-basket');
        return;
      }

      final message = merchantStatus == null
          ? 'Completez votre profil commercant avant de creer un panier.'
          : merchantStatus == 'PENDING'
              ? 'Votre profil commercant est en attente de validation.'
              : 'Votre profil commercant doit etre approuve pour creer un panier.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord commercant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: onCreateBasketPressed,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(tokenStorageServiceProvider).deleteToken();
              ref.read(authStateProvider.notifier).logout();
              context.go('/login');
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Bienvenue sur votre tableau de bord commercant.'),
            const SizedBox(height: 20),
            const Text('Vous pourrez gerer vos paniers, commandes et ventes ici.'),
            const SizedBox(height: 12),
            Text('Statut du commerce: ${merchantStatus ?? 'AUCUN'}'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onCreateBasketPressed,
              child: const Text('Creer un nouveau panier'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                context.push('/merchant-sales');
              },
              child: const Text('Voir mes ventes'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                context.push('/qr-scanner');
              },
              child: const Text('Scanner QR Code'),
            ),
          ],
        ),
      ),
    );
  }
}
