/// Auth state providers for FairTerms.
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

/// Provides a stream of Firebase [User] auth state changes.
final authStateProvider = StreamProvider<User?>((ref) {
  return AuthService.instance.authStateChanges;
});

/// True when the user has opted into guest mode (no Firebase sign-in).
final guestModeProvider = StateProvider<bool>((_) => false);

/// True when either a Firebase user is signed in OR guest mode is active.
final isAuthenticatedProvider = Provider<bool>((ref) {
  final guest = ref.watch(guestModeProvider);
  final auth = ref.watch(authStateProvider);
  return guest || auth.value != null;
});

/// Notifier that manages the sign-in flow state.
class SignInNotifier extends StateNotifier<AsyncValue<void>> {
  SignInNotifier() : super(const AsyncValue.data(null));

  /// Initiates Google Sign-In and updates state accordingly.
  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await AuthService.instance.signInWithGoogle();
    });
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await AuthService.instance.signOut();
    });
  }

  /// Resets the sign-in state to idle.
  void reset() {
    state = const AsyncValue.data(null);
  }
}

/// Provider for [SignInNotifier].
final signInProvider =
    StateNotifierProvider<SignInNotifier, AsyncValue<void>>(
  (_) => SignInNotifier(),
);
