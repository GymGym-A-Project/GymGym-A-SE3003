class AuthUser {
  const AuthUser({required this.id, required this.email});
  final String id;
  final String? email;
}

class AuthFailure implements Exception {
  const AuthFailure(this.code);
  final String code;

  /// The user closed the Google account picker; not an error to show.
  static const googleCanceled = 'google-sign-in-canceled';

  /// Google sign-in failed before Firebase was reached.
  static const googleFailed = 'google-sign-in-failed';
}

abstract interface class AuthRepository {
  AuthUser? get currentUser;
  Stream<AuthUser?> watch();
  Future<void> register({required String email, required String password});
  Future<void> signIn({required String email, required String password});
  Future<void> resetPassword(String email);

  /// Signs in with a Google account. A first sign-in creates the user; a
  /// returning user keeps the same UID. Throws [AuthFailure] with
  /// [AuthFailure.googleCanceled] when the user closes the picker.
  Future<void> signInWithGoogle();
  Future<void> signOut();
}
