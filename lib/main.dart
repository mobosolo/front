import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front/core/router/app_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:front/core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
    // Don't block app start if Firebase isn't ready yet.
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
      routerConfig: goRouter, // Use the GoRouter from the provider
    );
  }
}


