// Run only under firebase emulators:exec. Never targets production or Gemini.
const assert = require('node:assert/strict');
const authHost = process.env.FIREBASE_AUTH_EMULATOR_HOST;
const functionsHost = process.env.PLATEAU_FUNCTIONS_HOST;
assert(authHost && /^(127\.0\.0\.1|localhost):\d+$/.test(authHost));
assert(functionsHost && /^(127\.0\.0\.1|localhost):\d+$/.test(functionsHost));
const endpoint = `http://${functionsHost}/demo-gymgym/europe-west1/explainPlateau`;
async function main() {
  const signup = await fetch(`http://${authHost}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=local`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: `proxy-${Date.now()}@example.com`, password: 'Local-test-123!', returnSecureToken: true }),
  });
  assert.equal(signup.status, 200);
  const { idToken } = await signup.json();
  try {
    const denied = await fetch(endpoint, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: '{}' });
    assert.equal(denied.status, 401);
    const accepted = await fetch(endpoint, { method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${idToken}` },
      // Invalid metric input deliberately returns before any Gemini access.
      body: JSON.stringify({ summary: { email: 'never-forward@example.com' }, allowedExerciseIds: ['0030', '0033'] }),
    });
    assert.equal(accepted.status, 200);
    const result = await accepted.json();
    assert.equal(result.source, 'fallback');
    assert.equal(result.reason, 'invalid_input');
    assert.equal(result.disclaimer, 'Advisory only - not medical or coaching advice');
    assert.deepEqual(result.alternatives, ['0030', '0033']);
    console.log('Functions/Auth smoke passed: anonymous request rejected, real emulator token accepted, deterministic fallback returned. No Gemini request.');
  } finally {
    await fetch(`http://${authHost}/identitytoolkit.googleapis.com/v1/accounts:delete?key=local`, {
      method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ idToken }),
    });
  }
}
main().catch((error) => { console.error(error); process.exitCode = 1; });
