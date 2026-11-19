import 'package:google_sign_in/google_sign_in.dart';

/// Gets a Google ID token for Firebase from the Google account picker.
///
/// On Android the OAuth clients come from `google-services.json`, so no client
/// IDs are passed in Dart.
class GoogleIdTokens {
  GoogleIdTokens([GoogleSignIn? signIn])
    : _signIn = signIn ?? GoogleSignIn.instance;

  final GoogleSignIn _signIn;
  Future<void>? _initialized;

  Future<void> _ready() => _initialized ??= _signIn.initialize();

  /// Opens the account picker. Throws [GoogleSignInException], with
  /// [GoogleSignInExceptionCode.canceled] when the user closes it.
  Future<String> idToken() async {
    await _ready();
    final account = await _signIn.authenticate();
    final token = account.authentication.idToken;
    if (token == null) {
      throw const GoogleSignInException(
        code: GoogleSignInExceptionCode.unknownError,
        description: 'Google returned no ID token.',
      );
    }
    return token;
  }

  /// Forgets the chosen account so the picker shows again next time.
  Future<void> signOut() async {
    if (_initialized == null) return;
    await _ready();
    await _signIn.signOut();
  }
}
