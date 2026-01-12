import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final FirebaseAuth _firebaseAuth;

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
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        state = AuthState(status: AuthStatus.unauthenticated);
        return;
      }

      final user = UserModel(
        id: 0,
        email: firebaseUser.email ?? '',
        name: firebaseUser.displayName ?? firebaseUser.email ?? '',
        pictureUrl: firebaseUser.photoURL,
      );

      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      print('Error during Google sign in: $e');
      state = AuthState(status: AuthStatus.unauthenticated);
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
