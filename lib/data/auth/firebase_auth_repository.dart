import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'auth_repository.dart';
import 'google_id_tokens.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth, {GoogleIdTokens? google})
    : _google = google ?? GoogleIdTokens();
  final FirebaseAuth _auth;
  final GoogleIdTokens _google;

  AuthUser? _user(User? user) =>
      user == null ? null : AuthUser(id: user.uid, email: user.email);

  @override
  AuthUser? get currentUser => _user(_auth.currentUser);

  @override
  Stream<AuthUser?> watch() => _auth.authStateChanges().map(_user);

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(error.code);
    }
  }

  @override
  Future<void> register({required String email, required String password}) =>
      _run(() async {
        await _auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
      });

  @override
  Future<void> signIn({required String email, required String password}) =>
      _run(() async {
        await _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
      });

  @override
  Future<void> resetPassword(String email) =>
      _run(() => _auth.sendPasswordResetEmail(email: email.trim()));

  @override
  Future<void> signInWithGoogle() => _run(() async {
    final String idToken;
    try {
      idToken = await _google.idToken();
    } on GoogleSignInException catch (error) {
      throw AuthFailure(
        error.code == GoogleSignInExceptionCode.canceled
            ? AuthFailure.googleCanceled
            : AuthFailure.googleFailed,
      );
    }
    await _auth.signInWithCredential(
      GoogleAuthProvider.credential(idToken: idToken),
    );
  });

  @override
  Future<void> signOut() => _run(() async {
    await _auth.signOut();
    try {
      await _google.signOut();
    } on Object {
      // The Firebase session is already closed; a stale Google choice only
      // means the picker may preselect the last account.
    }
  });
}
