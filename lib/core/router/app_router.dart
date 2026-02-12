import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:front/features/auth/screens/login_screen.dart';
import 'package:front/features/auth/screens/register_screen.dart';
import 'package:front/features/auth/screens/splash_screen.dart';
import 'package:front/features/auth/screens/forgot_password_screen.dart';
import 'package:front/features/home/screens/home_screen.dart'; // Keep for now, but will redirect for clients
import 'package:front/features/profile/screens/profile_screen.dart';
import 'package:front/features/merchant/screens/merchant_profile_screen.dart'; // Updated import
import 'package:front/features/merchant/screens/merchant_dashboard_screen.dart';
import 'package:front/features/baskets/screens/basket_form_screen.dart'; // Updated import
import 'package:front/features/baskets/screens/basket_list_screen.dart'; // Import new screen
import 'package:front/features/baskets/screens/basket_details_screen.dart'; // Import new screen
import 'package:front/features/auth/providers/auth_providers.dart';
import 'package:front/features/orders/screens/order_confirmation_screen.dart';
import 'package:front/features/orders/screens/payment_method_selection_screen.dart';
import 'package:front/features/orders/screens/client_order_history_screen.dart';
import 'package:front/features/orders/screens/merchant_sales_history_screen.dart';
import 'package:front/features/orders/screens/qr_scanner_screen.dart';
import 'package:front/features/orders/screens/merchant_order_details_screen.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    routes: <RouteBase>[
      GoRoute(
        path: '/splash',
        builder: (BuildContext context, GoRouterState state) {
          return const SplashScreen();
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
        path: '/merchant-dashboard',
        builder: (BuildContext context, GoRouterState state) {
          return const MerchantDashboardScreen();
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
          );
        },
      ),
      GoRoute(
        path: '/client-orders',
        builder: (BuildContext context, GoRouterState state) {
          return const ClientOrderHistoryScreen();
        },
      ),
      GoRoute(
        path: '/merchant-sales',
        builder: (BuildContext context, GoRouterState state) {
          return const MerchantSalesHistoryScreen();
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
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final bool isAuthenticated = authState.isAuthenticated;
      final user = authState.user;

      // List of routes that don't require authentication
      final bool isUnauthenticatedRoute = ['/splash', '/login', '/register', '/forgot-password'].contains(state.uri.path);

      // If not authenticated and trying to access a protected route, redirect to login
      if (!isAuthenticated && !isUnauthenticatedRoute) {
        return '/login';
      }

      // If authenticated and trying to access an unauthenticated route, redirect to home
      // This prevents users from staying on splash/login/register once logged in
      if (isAuthenticated && isUnauthenticatedRoute) {
        return '/home'; // This will then be handled below
      }

      // Special handling for merchants
      if (isAuthenticated && user != null && user.role == 'MERCHANT') {
        if (user.merchant == null) {
          // No merchant profile yet: force registration.
          if (state.uri.path != '/merchant-register' && state.uri.path != '/profile') {
            return '/merchant-register';
          }
        } else if (user.merchant!.status == 'APPROVED') {
          // Allow approved merchants to access basket creation and editing
          if (state.uri.path == '/create-basket' || state.uri.path.startsWith('/edit-basket/')) {
            return null; // Allow navigation to these routes
          }
          // Redirect approved merchants to their dashboard if they are on home or client-facing routes
          if (state.uri.path == '/home' || state.uri.path == '/' || state.uri.path == '/merchant-register') {
            return '/merchant-dashboard';
          }
        } else {
          // Merchant profile exists but is not approved (PENDING/REJECTED):
          // never send back to registration form.
          if (state.uri.path == '/merchant-register' || state.uri.path == '/home' || state.uri.path == '/') {
            return '/merchant-dashboard';
          }
          // Non-approved merchants cannot create or edit baskets yet.
          if (state.uri.path == '/create-basket' || state.uri.path.startsWith('/edit-basket/')) {
            return '/merchant-dashboard';
          }
        }
      }
      
      // Special handling for clients (non-merchants)
      if (isAuthenticated && user != null && user.role == 'CLIENT') {
        // If client tries to go to /home or /, redirect to /baskets
        if (state.uri.path == '/home' || state.uri.path == '/') {
          return '/baskets';
        }
      }


      // No redirection needed
      return null;
    },
  );
});
