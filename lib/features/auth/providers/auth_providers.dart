import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front/features/auth/models/user_model.dart';
import 'package:front/features/auth/services/auth_service.dart';
import 'package:front/core/providers/dio_provider.dart';
import 'package:front/features/merchant/providers/merchant_providers.dart'; // Import merchant service provider
import 'package:front/features/merchant/services/merchant_service.dart'; // Import merchant service
import 'package:front/core/providers/notification_providers.dart'; // Import notification service provider
import 'package:front/core/services/notification_service.dart'; // Import notification service

// Provider for the AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthService(dio);
});

// Authentication state
class AuthState {
  final User? user;
  final bool isAuthenticated;

  AuthState({this.user, this.isAuthenticated = false});

  AuthState copyWith({User? user, bool? isAuthenticated}) {
    return AuthState(
      user: user ?? this.user,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

// State Notifier for Authentication
class AuthStateNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final MerchantService _merchantService; // Inject MerchantService
  final NotificationService _notificationService; // Inject NotificationService

  AuthStateNotifier(this._authService, this._merchantService, this._notificationService) : super(AuthState());

  Future<void> _handlePostAuthActions() async {
    await _notificationService.initialize();
    final fcmToken = await _notificationService.getFCMToken();
    if (fcmToken != null) {
      await _authService.sendFCMToken(fcmToken);
    }
  }

  Future<void> loadUser() async {
    try {
      final userData = await _authService.getMe();
      User user = User.fromJson(userData);

      if (user.role == 'MERCHANT') {
        try {
          final merchantData = await _merchantService.getMyMerchantProfile();
          user = user.copyWith(merchant: merchantData);
        } catch (e) {
          // Log error but don't fail auth, maybe merchant profile not created yet or not approved
          print('Error loading merchant profile: $e');
        }
      }
      state = AuthState(user: user, isAuthenticated: true);
      await _handlePostAuthActions();
    } catch (e) {
      state = AuthState(user: null, isAuthenticated: false);
    }
  }

  Future<void> login(String email, String password) async {
    final authResponse = await _authService.login(email, password);
    User user = User.fromJson(authResponse['user']);

    if (user.role == 'MERCHANT') {
      try {
        final merchantData = await _merchantService.getMyMerchantProfile();
        user = user.copyWith(merchant: merchantData);
      } catch (e) {
        print('Error loading merchant profile after login: $e');
      }
    }
    state = AuthState(user: user, isAuthenticated: true);
    await _handlePostAuthActions();
  }

  Future<void> register(String name, String email, String password, String phone, String role) async {
    final authResponse = await _authService.register(name, email, password, phone, role);
    User user = User.fromJson(authResponse['user']); // user object from authService.register

    if (user.role == 'MERCHANT') {
      try {
        // After successful user registration, we expect the frontend to create the merchant profile
        // The merchant profile won't be in authResponse, so we don't try to load it here
        // Instead, the redirect logic will send the user to MerchantProfileScreen
        // where they will create their merchant profile, and that screen will call authNotifier.loadUser() to refresh the state.
        // For consistency and to avoid immediate redirect loops, we can set the merchant to null here,
        // and let loadUser() handle it.
      } catch (e) {
        print('Error during initial merchant profile load after registration: $e');
      }
    }
    state = AuthState(user: user, isAuthenticated: true);
    await _handlePostAuthActions();
  }

  void logout() {
    // Here you should also clear the token from storage
    state = AuthState(user: null, isAuthenticated: false);
  }
}

// State Notifier Provider for Authentication
final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  final merchantService = ref.watch(merchantServiceProvider); // Watch merchant service
  final notificationService = ref.watch(notificationServiceProvider); // Watch notification service
  return AuthStateNotifier(authService, merchantService, notificationService);
});
