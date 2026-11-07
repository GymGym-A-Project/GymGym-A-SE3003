import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymgym_a/data/auth/auth_providers.dart';
import 'package:gymgym_a/data/auth/fake_auth_repository.dart';
import 'package:gymgym_a/data/models/routine.dart';
import 'package:gymgym_a/data/models/routine_item.dart';
import 'package:gymgym_a/data/repositories/routine_providers.dart';

Routine _routine(String id) => Routine(
  id: id,
  name: 'Push',
  order: 0,
  items: [RoutineItem(exerciseId: '1', targetSets: 3)],
  source: 'custom',
  updatedAt: DateTime.utc(2026, 11, 5),
);

void main() {
  late FakeAuthRepository auth;
  late ProviderContainer container;

  Future<void> switchUser(String email) async {
    await auth.signOut();
    await pumpEventQueue();
    await auth
        .register(email: email, password: 'secret123')
        .catchError((_) => auth.signIn(email: email, password: 'secret123'));
    await pumpEventQueue();
  }

  setUp(() {
    auth = FakeAuthRepository();
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(auth)],
    );
    addTearDown(container.dispose);
  });

  test('there is no repository while nobody is signed in', () async {
    final repository = container.listen(routineRepositoryProvider, (_, _) {});
    await pumpEventQueue();

    expect(repository.read(), isNull);
  });

  test('different uids get different repositories', () async {
    final repository = container.listen(routineRepositoryProvider, (_, _) {});

    await switchUser('a@example.com');
    final first = repository.read();
    await switchUser('b@example.com');
    final second = repository.read();

    expect(first, isNotNull);
    expect(second, isNotNull);
    expect(second, isNot(same(first)));
  });

  test('routines stay with their user for the whole session', () async {
    final repository = container.listen(routineRepositoryProvider, (_, _) {});
    final list = container.listen(routineListProvider, (_, _) {});

    await switchUser('a@example.com');
    await repository.read()!.save(_routine('a-routine'));
    await pumpEventQueue();
    expect(list.read().value?.single.id, 'a-routine');

    await switchUser('b@example.com');
    expect(list.read().value, isEmpty);

    await switchUser('a@example.com');
    expect(list.read().value?.single.id, 'a-routine');
  });

  test('routineByIdProvider returns null for an unknown id', () async {
    final known = container.listen(routineByIdProvider('a-routine'), (_, _) {});
    final unknown = container.listen(routineByIdProvider('nope'), (_, _) {});

    await switchUser('a@example.com');
    await container
        .read(routineRepositoryProvider)!
        .save(_routine('a-routine'));
    await pumpEventQueue();

    expect(known.read().value?.id, 'a-routine');
    expect(unknown.read().hasValue, isTrue);
    expect(unknown.read().value, isNull);
  });
}
