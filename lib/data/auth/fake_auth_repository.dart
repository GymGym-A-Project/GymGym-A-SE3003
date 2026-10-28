import 'dart:async';

import 'auth_repository.dart';

/// Test-only auth adapter. Never persists credentials or connects to Firebase.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({AuthUser? user}) {
    _user = user;
  }
  AuthUser? _user;
  final Map<String, String> _accounts = {};
  final Set<StreamController<AuthUser?>> _listeners = {};

  @override
  AuthUser? get currentUser => _user;

  @override
  Stream<AuthUser?> watch() {
    late final StreamController<AuthUser?> controller;
    controller = StreamController<AuthUser?>(
      onListen: () {
        _listeners.add(controller);
        controller.add(_user);
      },
      onCancel: () {
        _listeners.remove(controller);
      },
    );
    return controller.stream;
  }

  void _publish(AuthUser? user) {
    _user = user;
    for (final listener in _listeners) {
      listener.add(user);
    }
  }

  @override
  Future<void> register({
    required String email,
    required String password,
  }) async {
    email = email.trim().toLowerCase();
    if (!email.contains('@')) throw const AuthFailure('invalid-email');
    if (password.length < 6) throw const AuthFailure('weak-password');
    if (_accounts.containsKey(email)) {
      throw const AuthFailure('email-already-in-use');
    }
    _accounts[email] = password;
    _publish(AuthUser(id: email, email: email));
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    email = email.trim().toLowerCase();
    if (!_accounts.containsKey(email) || _accounts[email] != password) {
      throw const AuthFailure('invalid-credential');
    }
    _publish(AuthUser(id: email, email: email));
  }

  @override
  Future<void> resetPassword(String email) async {
    if (!email.trim().contains('@')) throw const AuthFailure('invalid-email');
  }

  @override
  Future<void> signOut() async => _publish(null);
}
