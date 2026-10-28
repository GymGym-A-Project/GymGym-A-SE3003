import 'package:firebase_auth/firebase_auth.dart';

import 'auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth);
  final FirebaseAuth _auth;

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
  Future<void> signOut() => _run(_auth.signOut);
}
