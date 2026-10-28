class AuthUser {
  const AuthUser({required this.id, required this.email});
  final String id;
  final String? email;
}

class AuthFailure implements Exception {
  const AuthFailure(this.code);
  final String code;
}

abstract interface class AuthRepository {
  AuthUser? get currentUser;
  Stream<AuthUser?> watch();
  Future<void> register({required String email, required String password});
  Future<void> signIn({required String email, required String password});
  Future<void> resetPassword(String email);
  Future<void> signOut();
}
