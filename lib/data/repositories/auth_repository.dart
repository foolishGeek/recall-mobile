// Recall · AuthRepository. Sign-in operations for Apple, Google, and email
// magic link. Wraps native SDKs + Supabase Auth; maps errors via guard().
// S08: controller calls these; AuthService.onAuthStateChange handles routing.

import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/app_env.dart';
import '../services/repo_exception.dart';
import '../services/supabase_service.dart';
import 'base_repository.dart';

class AuthRepository extends BaseRepository {
  AuthRepository(SupabaseService supabase) : super(supabase, 'signin');

  String get _redirectUrl => AppEnv.isProd
      ? 'app.recall://login-callback'
      : 'app.recall.staging://login-callback';

  /// Google sign-in: get idToken from Google SDK, then exchange via Supabase.
  /// Returns null when the user dismisses the Google picker (no error).
  Future<AuthResponse?> signInWithGoogle() async {
    const webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

    final googleSignIn = GoogleSignIn(
      serverClientId: webClientId.isNotEmpty ? webClientId : null,
    );

    final account = await googleSignIn.signIn();
    if (account == null) return null; // user cancelled

    return guard(() async {
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        throw const RepoException(
          RepoErrorCode.unknown,
          'Google sign-in returned no ID token.',
        );
      }

      return await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: auth.accessToken,
      );
    });
  }

  /// Apple sign-in: generate crypto nonce, get Apple credential, exchange.
  /// Returns null when the user dismisses the Apple sheet (no error).
  Future<AuthResponse?> signInWithApple() async {
    final rawNonce = _generateNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

    late final AuthorizationCredentialAppleID credential;
    try {
      credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return null;
      rethrow;
    }

    return guard(() async {
      final idToken = credential.identityToken;
      if (idToken == null) {
        throw const RepoException(
          RepoErrorCode.unknown,
          'Apple sign-in returned no identity token.',
        );
      }

      return await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );
    });
  }

  /// Email magic link via OTP. On success Supabase sends an email; the
  /// deep-link callback completes the session via onAuthStateChange.
  Future<void> signInWithMagicLink(String email) => guard(() async {
        await supabase.auth.signInWithOtp(
          email: email,
          emailRedirectTo: _redirectUrl,
        );
      });

  Future<void> signOut() => guard(() async {
        await supabase.auth.signOut();
      });

  /// Cryptographically random 32-byte nonce for Apple PKCE.
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }
}
