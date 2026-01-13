import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hisabi/core/models/user_model.dart';
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
  final GoogleSignIn _googleSignIn;

  AuthNotifier()
      : _googleSignIn = GoogleSignIn(
          clientId: kIsWeb
              ? dotenv.get('GOOGLE_CLIENT_ID', fallback: '')
              : null,
          scopes: const [
            'email',
            'profile',
          ],
        ),
        super(AuthState(
          status: AuthStatus.authenticated,
          user: UserModel(
            id: 0,
            email: 'user@example.com',
            name: 'Hisabi User',
          ),
        ));

  Future<void> checkAuthStatus() async {
    // Check if user is stored locally
    final authData = await StorageService.loadAuthState();
    
    if (authData != null) {
      final user = UserModel(
        id: 0,
        email: authData['email'] as String? ?? 'user@example.com',
        name: authData['name'] as String? ?? 'Hisabi User',
        pictureUrl: authData['pictureUrl'] as String?,
      );
      
      state = AuthState(status: AuthStatus.authenticated, user: user);
      return;
    }

    // Default to authenticated even if no local data exists to skip login
    state = AuthState(
      status: AuthStatus.authenticated,
      user: UserModel(
        id: 0,
        email: 'user@example.com',
        name: 'Hisabi User',
      ),
    );
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

      // Save user to local storage
      await StorageService.saveAuthState(
        user.email,
        user.name,
        user.pictureUrl,
      );

      // Initialize user storage
      await StorageService.initializeUserStorage(user.email);

      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      print('Error during Google sign in: $e');
    }
  }

  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
      await StorageService.clearAuthState();
      // Instead of unauthenticated, we just stay "authenticated" as guest for this specific request
      state = AuthState(
        status: AuthStatus.authenticated,
        user: UserModel(
          id: 0,
          email: 'user@example.com',
          name: 'Hisabi User',
        ),
      );
    } catch (e) {
      print('Error during logout: $e');
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final notifier = AuthNotifier();
  // Initialize auth state asynchronously without blocking
  notifier.checkAuthStatus();
  return notifier;
});
