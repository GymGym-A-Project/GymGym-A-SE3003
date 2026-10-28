import 'package:flutter_test/flutter_test.dart';
import 'package:gymgym_a/data/auth/auth_repository.dart';
import 'package:gymgym_a/data/auth/fake_auth_repository.dart';

void main() {
  test(
    'auth observers see initial, register, sign out and sign in states',
    () async {
      final repository = FakeAuthRepository();
      final observed = expectLater(
        repository.watch().take(4),
        emitsInOrder([isNull, isA<AuthUser>(), isNull, isA<AuthUser>()]),
      );
      await repository.register(
        email: ' user@example.com ',
        password: 'secret123',
      );
      expect(repository.currentUser!.email, 'user@example.com');
      await repository.signOut();
      expect(repository.currentUser, isNull);
      await repository.signIn(email: 'user@example.com', password: 'secret123');
      await observed;
    },
  );

  test(
    'fake rejects invalid credentials and duplicate registrations',
    () async {
      final repository = FakeAuthRepository();
      await expectLater(
        repository.register(email: 'bad', password: 'secret123'),
        throwsA(isA<AuthFailure>()),
      );
      await expectLater(
        repository.register(email: 'u@example.com', password: '123'),
        throwsA(isA<AuthFailure>()),
      );
      await repository.register(email: 'u@example.com', password: 'secret123');
      await expectLater(
        repository.register(email: 'u@example.com', password: 'secret123'),
        throwsA(isA<AuthFailure>()),
      );
      await repository.signOut();
      await expectLater(
        repository.signIn(email: 'u@example.com', password: 'incorrect'),
        throwsA(isA<AuthFailure>()),
      );
      expect(repository.currentUser, isNull);
      await repository.resetPassword('unknown@example.com');
      expect(repository.currentUser, isNull);
    },
  );
}
