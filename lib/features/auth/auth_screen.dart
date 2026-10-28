import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth/auth_providers.dart';
import '../../data/auth/auth_repository.dart';

enum _Mode { signIn, register, reset }

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  _Mode _mode = _Mode.signIn;
  bool _busy = false;
  String? _message;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _changeMode(_Mode mode) => setState(() {
    _mode = mode;
    _message = null;
    _password.clear();
    _confirm.clear();
    _form.currentState?.reset();
  });

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    final repository = ref.read(authRepositoryProvider);
    try {
      switch (_mode) {
        case _Mode.signIn:
          await repository.signIn(email: _email.text, password: _password.text);
        case _Mode.register:
          await repository.register(
            email: _email.text,
            password: _password.text,
          );
        case _Mode.reset:
          await repository.resetPassword(_email.text);
          if (mounted) {
            setState(() {
              _message =
                  'If an account exists, a password reset email has been sent.';
            });
          }
      }
    } on AuthFailure catch (error) {
      if (mounted) {
        setState(() {
          _message = switch (error.code) {
            'invalid-email' => 'Enter a valid email address.',
            'weak-password' =>
              'Choose a stronger password (at least 6 characters).',
            'email-already-in-use' =>
              'This email is already registered. Try signing in.',
            'invalid-credential' || 'user-not-found' || 'wrong-password' =>
              _mode == _Mode.reset
                  ? 'If an account exists, a password reset email has been sent.'
                  : 'Email or password is incorrect.',
            'too-many-requests' => 'Too many attempts. Please try again later.',
            'network-request-failed' => 'Check your connection and try again.',
            _ => 'Unable to complete the request. Please try again.',
          };
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _message = 'Unable to complete the request. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (_mode) {
      _Mode.signIn => 'Sign in',
      _Mode.register => 'Create account',
      _Mode.reset => 'Reset password',
    };
    return Scaffold(
      appBar: AppBar(title: const Text('GymGym-A')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _form,
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      key: const ValueKey('auth-email'),
                      controller: _email,
                      enabled: !_busy,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (value) =>
                          RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                              .hasMatch(value?.trim() ?? '')
                          ? null
                          : 'Enter a valid email address.',
                    ),
                    if (_mode != _Mode.reset) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const ValueKey('auth-password'),
                        controller: _password,
                        enabled: !_busy,
                        obscureText: true,
                        autocorrect: false,
                        enableSuggestions: false,
                        autofillHints: [
                          _mode == _Mode.register
                              ? AutofillHints.newPassword
                              : AutofillHints.password,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Password',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter your password.';
                          }
                          if (_mode == _Mode.register && value.length < 6) {
                            return 'Use at least 6 characters.';
                          }
                          return null;
                        },
                      ),
                    ],
                    if (_mode == _Mode.register) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const ValueKey('auth-confirm'),
                        controller: _confirm,
                        enabled: !_busy,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Confirm password',
                        ),
                        validator: (value) => value == _password.text
                            ? null
                            : 'Passwords do not match.',
                      ),
                    ],
                    if (_message != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          _message!,
                          key: const ValueKey('auth-message'),
                        ),
                      ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: Text(_busy ? 'Please wait…' : title),
                    ),
                    if (_mode == _Mode.signIn) ...[
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => _changeMode(_Mode.register),
                        child: const Text('Create account'),
                      ),
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => _changeMode(_Mode.reset),
                        child: const Text('Forgot password?'),
                      ),
                    ] else
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => _changeMode(_Mode.signIn),
                        child: const Text('Back to sign in'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
