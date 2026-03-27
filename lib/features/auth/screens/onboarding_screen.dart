import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:front/core/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _current = 0;

  final List<_Slide> _slides = const [
    _Slide(
      icon: Icons.shopping_basket,
      title: 'Sauvez des repas à petit prix',
      subtitle: 'Achetez les invendus des commerces près de vous.',
      color: AppTheme.primary,
    ),
    _Slide(
      icon: Icons.smartphone,
      title: 'Réservez en quelques clics',
      subtitle: 'Choisissez un panier et payez via Mobile Money.',
      color: AppTheme.secondary,
    ),
    _Slide(
      icon: Icons.qr_code_2,
      title: 'Retirez avec un QR code',
      subtitle: 'Montrez votre code et récupérez votre repas.',
      color: AppTheme.success,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }


  void _next() {
    if (_current < _slides.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      context.go('/register');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (index) => setState(() => _current = index),
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.background,
                          ),
                          child: Center(
                            child: Icon(slide.icon, size: 48, color: slide.color),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          slide.subtitle,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: AppTheme.mutedForeground),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (index) {
                final bool active = index == _current;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: active ? 32 : 8,
                  decoration: BoxDecoration(
                    color: active ? AppTheme.primary : Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _next,
                      icon: const Icon(Icons.chevron_right),
                      label: Text(_current == _slides.length - 1 ? 'Commencer' : 'Suivant'),
                      style: ElevatedButton.styleFrom(
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Se connecter'),
                    ),
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
}

class _Slide {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _Slide({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}
