import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hisabi/core/models/user_model.dart';
import 'package:hisabi/core/api/api_client.dart';
import 'package:hisabi/core/storage/storage_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

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

  AuthNotifier(this._apiClient)
      : _googleSignIn = GoogleSignIn(
          clientId: kIsWeb
              ? '354846083694-ol920da7pne2uuvfhs1pap3brc432rul.apps.googleusercontent.com'
              : null,
          scopes: const [
            'email',
            'profile',
          ],
        ),
        super(AuthState(status: AuthStatus.unauthenticated));

  Future<void> checkAuthStatus() async {
    final savedAuth = await StorageService.loadAuthState();
    if (savedAuth != null) {
      // Try to get current Google user to refresh profile picture
      GoogleSignInAccount? currentUser;
      try {
        currentUser = await _googleSignIn.signInSilently();
      } catch (_) {
        // If silent sign-in fails, try to get current user
        currentUser = _googleSignIn.currentUser;
      }

      // Use current Google user's photo if available, otherwise use saved
      final pictureUrl = currentUser?.photoUrl ?? savedAuth['pictureUrl'] as String?;
      final name = currentUser?.displayName ?? savedAuth['name'] as String;
      final email = currentUser?.email ?? savedAuth['email'] as String;

      final user = UserModel(
        id: 0,
        email: email,
        name: name,
        pictureUrl: pictureUrl,
      );
      
      // Update saved auth state with latest picture if it changed
      if (currentUser?.photoUrl != null && currentUser!.photoUrl != savedAuth['pictureUrl']) {
        await StorageService.saveAuthState(user.email, user.name, user.pictureUrl);
      }
      
      // Initialize user storage when restoring auth state
      await StorageService.initializeUserStorage(user.email);
      state = AuthState(status: AuthStatus.authenticated, user: user);
      return;
    }

    try {
      final data = await _apiClient
          .get('/api/user')
          .timeout(const Duration(seconds: 3));
      final user = UserModel.fromJson(data);
      
      // Try to get current Google user to ensure we have the latest photo
      GoogleSignInAccount? currentUser;
      try {
        currentUser = await _googleSignIn.signInSilently();
      } catch (_) {
        currentUser = _googleSignIn.currentUser;
      }
      
      // Use Google user's photo if available, otherwise use API response
      final pictureUrl = currentUser?.photoUrl ?? user.pictureUrl;
      final finalUser = UserModel(
        id: user.id,
        email: user.email,
        name: user.name,
        pictureUrl: pictureUrl,
      );
      
      await StorageService.saveAuthState(finalUser.email, finalUser.name, finalUser.pictureUrl);
      state = AuthState(status: AuthStatus.authenticated, user: finalUser);
    } catch (_) {
      state = AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> loginWithGoogle() async {
    try {
      await _googleSignIn.signOut();

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return;
      }

      final user = UserModel(
        id: 0,
        email: googleUser.email,
        name: googleUser.displayName ?? googleUser.email,
        pictureUrl: googleUser.photoUrl,
      );

      await StorageService.saveAuthState(user.email, user.name, user.pictureUrl);

      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (_) {
      state = AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> logout() async {
    await StorageService.clearAuthState();
    await _googleSignIn.signOut();
    state = AuthState(status: AuthStatus.unauthenticated);
  }
}

final apiClientProvider = Provider((ref) => ApiClient());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthNotifier(apiClient)..checkAuthStatus();
});
