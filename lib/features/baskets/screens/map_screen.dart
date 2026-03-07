import 'package:flutter/material.dart';
import 'package:front/core/theme/app_theme.dart';
import 'package:front/core/widgets/bottom_nav.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Carte')),
      bottomNavigationBar: const BottomNav(
        activeTab: 'map',
        role: 'CLIENT',
      ),
      body: const Center(
        child: Text('Carte indisponible pour le moment.'),
      ),
    );
  }
}
