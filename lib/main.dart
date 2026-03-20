import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front/core/router/app_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:front/core/theme/app_theme.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Initialisation de Stripe
  Stripe.publishableKey = "pk_test_51TCj72D2JQsWgHFlHrNUHe4Sqoy94QWFvMsWJCWv6DCAzynUILKfvOb1UDuoHbbpfkf7lKvSnpe5OVctYcNtAUhR00PT69VqBF";
  await Stripe.instance.applySettings();
  
  // 2. Initialisation de Firebase (L'appel manquant est ici !)
  await _initFirebase();
  
  runApp(const ProviderScope(child: MyApp()));
}

Future<void> _initFirebase() async {
  try {
    if (kIsWeb) {
      const webOptions = FirebaseOptions(
        apiKey: 'AIzaSyBXiI70SYbkIKYIHjifD6Kb93ABYM3EL00',
        authDomain: 'meal-flavor.firebaseapp.com',
        projectId: 'meal-flavor',
        storageBucket: 'meal-flavor.firebasestorage.app',
        messagingSenderId: '1080370938209',
        appId: '1:1080370938209:web:b843f114174a3a258c8520',
        measurementId: 'G-VQ2Q4WW5TS',
      );
      await Firebase.initializeApp(options: webOptions);
      return;
    }
    await Firebase.initializeApp();
  } catch (e, st) {
    debugPrint('Firebase init failed: $e');
    debugPrint('$st');
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goRouter = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'MealFlavor',
      theme: AppTheme.light(),
      debugShowCheckedModeBanner: false,
      routerConfig: goRouter, 
    );
  }
}