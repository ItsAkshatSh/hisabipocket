// features/auth/providers/auth_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hisabi/core/models/user_model.dart';
import 'package:hisabi/core/api/api_client.dart';
import 'package:hisabi/core/storage/storage_service.dart';

// Enum for Auth status
enum AuthStatus { unknown, authenticated, unauthenticated }

// State class for Auth
class AuthState {
  final AuthStatus status;
  final UserModel? user;

  AuthState({required this.status, this.user});

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _apiClient;
  final GoogleSignIn _googleSignIn;

  // Start as unauthenticated to avoid getting stuck in a splash state.
  AuthNotifier(this._apiClient)
      : _googleSignIn = GoogleSignIn(
          // On Web we must pass the clientId; on Android/iOS it comes from platform config.
          clientId: kIsWeb
              ? '354846083694-ol920da7pne2uuvfhs1pap3brc432rul.apps.googleusercontent.com'
              : null,
          scopes: const [
            'email',
            'profile',
          ],
        ),
        super(AuthState(status: AuthStatus.unauthenticated));

  // Check auth on startup
  Future<void> checkAuthStatus() async {
    // First check local storage for persistent login
    final savedAuth = await StorageService.loadAuthState();
    if (savedAuth != null) {
      final user = UserModel(
        id: 0,
        email: savedAuth['email'] as String,
        name: savedAuth['name'] as String,
        pictureUrl: savedAuth['pictureUrl'] as String?,
      );
      state = AuthState(status: AuthStatus.authenticated, user: user);
      return;
    }

    // Fallback to API check (for future backend integration)
    try {
      final data = await _apiClient
          .get('/api/user')
          .timeout(const Duration(seconds: 3));
      final user = UserModel.fromJson(data);
      // Save to persistent storage
      await StorageService.saveAuthState(user.email, user.name, user.pictureUrl);
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (_) {
      // If anything fails (network, timeout, parsing), default to unauthenticated
      state = AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> loginWithGoogle() async {
    try {
      // Sign out any existing session first to force account picker if desired.
      await _googleSignIn.signOut();

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled the flow.
        return;
      }

      // If you later add a backend, you can use this:
      // final googleAuth = await googleUser.authentication;
      // and send googleAuth.idToken / accessToken to your API.

      // For now, we treat Google as the source of truth and build a UserModel directly.
      final user = UserModel(
        // `UserModel.id` is an int; for now we just use a dummy value and
        // rely on the email as the stable identifier.
        id: 0,
        email: googleUser.email,
        name: googleUser.displayName ?? googleUser.email,
        pictureUrl: googleUser.photoUrl,
      );

      // Save to persistent storage for one-time login
      await StorageService.saveAuthState(user.email, user.name, user.pictureUrl);

      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (_) {
      // If anything fails, keep the user logged out.
      state = AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> logout() async {
    // Clear persistent auth state
    await StorageService.clearAuthState();
    // Sign out from Google
    await _googleSignIn.signOut();
    // Update state
    state = AuthState(status: AuthStatus.unauthenticated);
  }
}

final apiClientProvider = Provider((ref) => ApiClient());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthNotifier(apiClient)..checkAuthStatus();
});
