import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:front/features/auth/screens/login_screen.dart';
import 'package:front/features/auth/screens/register_screen.dart';
import 'package:front/features/auth/screens/splash_screen.dart';
import 'package:front/features/auth/screens/forgot_password_screen.dart';
import 'package:front/features/auth/screens/onboarding_screen.dart';
import 'package:front/features/home/screens/home_screen.dart'; // Keep for now, but will redirect for clients
import 'package:front/features/profile/screens/profile_screen.dart';
import 'package:front/features/merchant/screens/merchant_profile_screen.dart'; // Updated import
import 'package:front/features/merchant/screens/merchant_dashboard_screen.dart';
import 'package:front/features/baskets/screens/basket_form_screen.dart'; // Updated import
import 'package:front/features/baskets/screens/basket_list_screen.dart'; // Import new screen
import 'package:front/features/baskets/screens/basket_details_screen.dart'; // Import new screen
import 'package:front/features/baskets/screens/map_screen.dart';
import 'package:front/features/merchant/screens/merchant_baskets_screen.dart';
import 'package:front/features/auth/providers/auth_providers.dart';
import 'package:front/features/orders/screens/order_confirmation_screen.dart';
import 'package:front/features/orders/screens/payment_method_selection_screen.dart';
import 'package:front/features/orders/screens/client_order_history_screen.dart';
import 'package:front/features/orders/screens/merchant_sales_history_screen.dart';
import 'package:front/features/orders/screens/qr_scanner_screen.dart';
import 'package:front/features/orders/screens/merchant_order_details_screen.dart';
import 'package:front/features/admin/screens/admin_dashboard_screen.dart';
import 'package:front/features/admin/screens/admin_merchants_screen.dart';
import 'package:front/features/admin/screens/admin_users_screen.dart';

final _routerRefreshProvider = Provider<ValueNotifier<int>>((ref) {
  final notifier = ValueNotifier<int>(0);
  ref.listen<AuthState>(authStateProvider, (_, __) {
    notifier.value++;
  });
  ref.onDispose(notifier.dispose);
  return notifier;
});

final goRouterProvider = Provider<GoRouter>((ref) {
  final refreshListenable = ref.watch(_routerRefreshProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refreshListenable,
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        redirect: (_, __) => '/home',
      ),
      GoRoute(
        path: '/splash',
        builder: (BuildContext context, GoRouterState state) {
          return const SplashScreen();
        },
      ),
      GoRoute(
        path: '/onboarding',
        builder: (BuildContext context, GoRouterState state) {
          return const OnboardingScreen();
        },
      ),
      GoRoute(
        path: '/login',
        builder: (BuildContext context, GoRouterState state) {
          return const LoginScreen();
        },
      ),
      GoRoute(
        path: '/register',
        builder: (BuildContext context, GoRouterState state) {
          return const RegisterScreen();
        },
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (BuildContext context, GoRouterState state) {
          return const ForgotPasswordScreen();
        },
      ),
      GoRoute(
        path: '/home', // For now, this will redirect to /baskets for clients
        builder: (BuildContext context, GoRouterState state) {
          return const HomeScreen(); // Placeholder
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (BuildContext context, GoRouterState state) {
          return const ProfileScreen();
        },
      ),
      GoRoute(
        path: '/merchant-register',
        builder: (BuildContext context, GoRouterState state) {
          return const MerchantProfileScreen(); // Use new name
        },
      ),
      GoRoute(
        path: '/merchant-profile',
        builder: (BuildContext context, GoRouterState state) {
          return const MerchantProfileScreen();
        },
      ),
      GoRoute(
        path: '/merchant-dashboard',
        builder: (BuildContext context, GoRouterState state) {
          return const MerchantDashboardScreen();
        },
      ),
      GoRoute(
        path: '/merchant-baskets',
        builder: (BuildContext context, GoRouterState state) {
          return const MerchantBasketsScreen();
        },
      ),
      GoRoute(
        path: '/create-basket',
        builder: (BuildContext context, GoRouterState state) {
          return const BasketFormScreen(); // Use new name
        },
      ),
      GoRoute(
        path: '/baskets',
        builder: (BuildContext context, GoRouterState state) {
          return const BasketListScreen();
        },
      ),
      GoRoute(
        path: '/map',
        builder: (BuildContext context, GoRouterState state) {
          final lat = double.tryParse(state.uri.queryParameters['lat'] ?? '');
          final lon = double.tryParse(state.uri.queryParameters['lon'] ?? '');
          final label = state.uri.queryParameters['label'];
          final basketId = state.uri.queryParameters['basketId'];
          return MapScreen(
            targetLat: lat,
            targetLon: lon,
            targetLabel: label,
            targetBasketId: basketId,
          );
        },
      ),
      GoRoute(
        path: '/basket-details/:basketId',
        builder: (BuildContext context, GoRouterState state) {
          final basketId = state.pathParameters['basketId']!;
          return BasketDetailsScreen(basketId: basketId);
        },
      ),
      GoRoute(
        path: '/merchant-profile-edit/:merchantId',
        builder: (BuildContext context, GoRouterState state) {
          final merchantId = state.pathParameters['merchantId'];
          return MerchantProfileScreen(merchantId: merchantId);
        },
      ),
      GoRoute(
        path: '/edit-basket/:basketId',
        builder: (BuildContext context, GoRouterState state) {
          final basketId = state.pathParameters['basketId']!;
          return BasketFormScreen(basketId: basketId);
        },
      ),
      GoRoute(
        path: '/order-confirmation/:orderId',
        builder: (BuildContext context, GoRouterState state) {
          final orderId = state.pathParameters['orderId']!;
          return OrderConfirmationScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: '/select-payment-method',
        builder: (BuildContext context, GoRouterState state) {
          final extra = state.extra as Map<String, dynamic>;
          return PaymentMethodSelectionScreen(
            basketId: extra['basketId'] as String,
            price: extra['price'] as int,
            basketTitle: extra['basketTitle'] as String?,
            merchantName: extra['merchantName'] as String?,
            pickupStart: extra['pickupStart'] as String?,
            pickupEnd: extra['pickupEnd'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/client-orders',
        builder: (BuildContext context, GoRouterState state) {
          final initialTab = state.uri.queryParameters['tab'];
          final showValidatedMessage = state.uri.queryParameters['validated'] == '1';
          return ClientOrderHistoryScreen(
            initialTab: initialTab,
            showValidatedMessage: showValidatedMessage,
          );
        },
      ),
      GoRoute(
        path: '/merchant-sales',
        builder: (BuildContext context, GoRouterState state) {
          final initialTab = state.uri.queryParameters['tab'];
          final showValidatedMessage = state.uri.queryParameters['validated'] == '1';
          return MerchantSalesHistoryScreen(
            initialTab: initialTab,
            showValidatedMessage: showValidatedMessage,
          );
        },
      ),
      GoRoute(
        path: '/merchant-orders/:orderId',
        builder: (BuildContext context, GoRouterState state) {
          final orderId = state.pathParameters['orderId']!;
          return MerchantOrderDetailsScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: '/qr-scanner',
        builder: (BuildContext context, GoRouterState state) {
          return const QrScannerScreen();
        },
      ),
      GoRoute(
        path: '/admin-dashboard',
        builder: (BuildContext context, GoRouterState state) {
          return const AdminDashboardScreen();
        },
      ),
      GoRoute(
        path: '/admin-merchants',
        builder: (BuildContext context, GoRouterState state) {
          return const AdminMerchantsScreen();
        },
      ),
      GoRoute(
        path: '/admin-users',
        builder: (BuildContext context, GoRouterState state) {
          return const AdminUsersScreen();
        },
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final authState = ref.read(authStateProvider);
      final bool isAuthenticated = authState.isAuthenticated;
      final user = authState.user;
      final path = state.uri.path;

      const publicRoutes = {
        '/splash',
        '/onboarding',
        '/login',
        '/register',
        '/forgot-password',
      };
      final isPublicRoute = publicRoutes.contains(path);
      final isMerchantArea = path.startsWith('/merchant-') ||
          path == '/merchant-dashboard' ||
          path == '/merchant-baskets' ||
          path == '/create-basket' ||
          path.startsWith('/edit-basket/') ||
          path == '/qr-scanner';
      final isAdminArea = path.startsWith('/admin-');

      if (!isAuthenticated) {
        if (!isPublicRoute) return '/login';
        return null;
      }

      if (user == null) {
        return '/login';
      }

      if (isPublicRoute) {
        if (user.role == 'MERCHANT') return '/merchant-dashboard';
        if (user.role == 'ADMIN') return '/admin-dashboard';
        return '/baskets';
      }

      if (isAdminArea && user.role != 'ADMIN') {
        return user.role == 'MERCHANT' ? '/merchant-dashboard' : '/baskets';
      }

      if (user.role == 'ADMIN') {
        if (!isAdminArea && path != '/profile') {
          return '/admin-dashboard';
        }
        return null;
      }

      if (user.role == 'MERCHANT') {
        if (user.merchant == null) {
          if (path != '/merchant-register' && path != '/profile') {
            return '/merchant-register';
          }
        } else if (user.merchant!.status == 'APPROVED') {
          if (path == '/home' || path == '/merchant-register') {
            return '/merchant-dashboard';
          }
        } else {
          if (path == '/merchant-register' || path == '/home') {
            return '/merchant-dashboard';
          }
          if (path == '/create-basket' || path.startsWith('/edit-basket/')) {
            return '/merchant-dashboard';
          }
        }
        return null;
      }

      // Client navigation guards.
      if (user.role == 'CLIENT') {
        if (path == '/home' || path == '/merchant-register') {
          return '/baskets';
        }
        if (isMerchantArea) {
          return '/baskets';
        }
      }

      return null;
    },
  );
});
