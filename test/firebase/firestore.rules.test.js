import { after, before, beforeEach, test } from 'node:test';
import { readFileSync } from 'node:fs';
import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { doc, setDoc, getDoc, deleteDoc, Timestamp } from 'firebase/firestore';

let environment;
const routine = () => ({
  id: 'push', name: 'Push', order: 0, source: 'custom', updatedAt: Timestamp.now(),
  items: [{ exerciseId: '0025', targetSets: 3 }],
});
const workout = () => ({
  id: 'w1', routineId: 'push', startedAt: Timestamp.now(), finishedAt: null,
  exerciseIds: ['0025'], exercises: [{ exerciseId: '0025', sets: [] }], totalVolume: 0,
});
before(async () => {
  environment = await initializeTestEnvironment({
    projectId: 'demo-gymgym',
    firestore: { rules: readFileSync(new URL('../../firestore.rules', import.meta.url), 'utf8') },
  });
});
beforeEach(async () => environment.clearFirestore());
after(async () => { await environment?.cleanup(); });

test('owners can create, read, update and delete their routines', async () => {
  const db = environment.authenticatedContext('alice').firestore();
  const reference = doc(db, 'users/alice/routines/push');
  await assertSucceeds(setDoc(reference, routine()));
  await assertSucceeds(getDoc(reference));
  await assertSucceeds(setDoc(reference, { ...routine(), source: 'starter:ppl' }));
  await assertSucceeds(deleteDoc(reference));
});

test('signed-out and other users cannot access private data', async () => {
  for (const db of [environment.unauthenticatedContext().firestore(),
    environment.authenticatedContext('bob').firestore()]) {
    for (const collection of ['routines', 'workouts', 'lastPerformance']) {
      const reference = doc(db, `users/alice/${collection}/push`);
      await assertFails(getDoc(reference));
      await assertFails(setDoc(reference, routine()));
      await assertFails(deleteDoc(reference));
    }
  }
});

test('routine validation rejects malformed values and accepts 15 items', async () => {
  const db = environment.authenticatedContext('alice').firestore();
  const reference = doc(db, 'users/alice/routines/push');
  for (const change of [{ name: ' ' }, { items: [] }, { id: 'different' },
    { updatedAt: 'not-a-timestamp' }, { items: [{ exerciseId: '0025', targetSets: 0 }] },
    { items: Array(16).fill({ exerciseId: '0025', targetSets: 3 }) }]) {
    await assertFails(setDoc(reference, { ...routine(), ...change }));
  }
  await assertSucceeds(setDoc(reference, { ...routine(),
    items: Array(15).fill({ exerciseId: '0025', targetSets: 3 }) }));
});

test('workout timestamps and user isolation are enforced', async () => {
  const db = environment.authenticatedContext('alice').firestore();
  const reference = doc(db, 'users/alice/workouts/w1');
  await assertSucceeds(setDoc(reference, workout()));
  await assertSucceeds(getDoc(reference));
  await assertFails(setDoc(reference, { ...workout(), finishedAt: Timestamp.fromMillis(0) }));
  await assertFails(setDoc(reference, { ...workout(), totalVolume: -1 }));
  await assertFails(setDoc(doc(db, 'users/alice/unknown/x'), workout()));
  await assertFails(setDoc(doc(db, 'users/alice/lastPerformance/0025'), { sets: [] }));
});
