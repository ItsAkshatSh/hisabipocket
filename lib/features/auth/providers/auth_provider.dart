import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final FirebaseAuth _firebaseAuth;

  AuthNotifier()
      : _googleSignIn = GoogleSignIn(
          clientId: kIsWeb
              ? '354846083694-ol920da7pne2uuvfhs1pap3brc432rul.apps.googleusercontent.com'
              : null,
          scopes: const [
            'email',
            'profile',
          ],
          serverClientId: kIsWeb
              ? null
              : '534192209348-gg7nnp03rn0aibq4h69bh7or3d70nvnf.apps.googleusercontent.com',
        ),
        _firebaseAuth = FirebaseAuth.instance,
        super(AuthState(status: AuthStatus.unauthenticated));

  Future<void> checkAuthStatus() async {
    final firebaseUser = _firebaseAuth.currentUser;
    
    if (firebaseUser != null) {
      final user = UserModel(
        id: 0,
        email: firebaseUser.email ?? '',
        name: firebaseUser.displayName ?? firebaseUser.email ?? '',
        pictureUrl: firebaseUser.photoURL,
      );
      
      state = AuthState(status: AuthStatus.authenticated, user: user);
      return;
    }

    state = AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> loginWithGoogle() async {
    try {
      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google Sign-In was cancelled by user');
      }

      final googleAuth = await googleUser.authentication;
      
      if (googleAuth.accessToken == null && googleAuth.idToken == null) {
        throw Exception('Failed to get authentication tokens from Google');
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw Exception('Firebase authentication failed - no user returned');
      }

      final user = UserModel(
        id: 0,
        email: firebaseUser.email ?? '',
        name: firebaseUser.displayName ?? firebaseUser.email ?? '',
        pictureUrl: firebaseUser.photoURL,
      );

      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (e, stackTrace) {
      print('Error during Google sign in: $e');
      print('Stack trace: $stackTrace');
      state = AuthState(status: AuthStatus.unauthenticated);
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
      await _googleSignIn.signOut();
      await StorageService.clearAuthState();
      state = AuthState(status: AuthStatus.unauthenticated);
    } catch (e) {
      print('Error during logout: $e');
      state = AuthState(status: AuthStatus.unauthenticated);
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier()..checkAuthStatus();
});
