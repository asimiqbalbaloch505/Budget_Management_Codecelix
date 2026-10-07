import 'package:flutter/material.dart';
import 'auth_widgets.dart';

class SignupScreen extends StatefulWidget {
  /// Integration hooks. Field names match the API contract: fullName, email, password.
  /// onSignup returns null on success, or an error message to show.
  final Future<String?> Function(String fullName, String email, String password)?
  onSignup;
  final VoidCallback? onSuccess;
  const SignupScreen({super.key, this.onSignup, this.onSuccess});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _agree = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (!_agree) {
      setState(() => _error = 'Please accept the Terms and Conditions.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final err = await widget.onSignup
        ?.call(_name.text.trim(), _email.text.trim(), _pass.text);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = err;
    });
    if (err == null) widget.onSuccess?.call();
  }

  @override
  Widget build(BuildContext context) {
    return AuthPage(showBack: true, children: [
      const SizedBox(height: 20),
      const Align(
          alignment: Alignment.centerLeft,
          child: AuthIcon(Icons.menu_book_outlined)),
      const SizedBox(height: 16),
      const AuthHeading('Create your account'),
      const SizedBox(height: 6),
      const AuthSubtitle('Start budgeting smarter in under a minute.'),
      const SizedBox(height: 22),
      Form(
        key: _form,
        child: Column(children: [
          AuthField(
              label: 'Full name',
              hint: 'Aarav Sharma',
              controller: _name,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Enter your name.'
                  : null),
          AuthField(
              label: 'Email',
              hint: 'aarav@example.com',
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              validator: validateEmail),
          AuthField(
              label: 'Password',
              hint: 'Create a password',
              controller: _pass,
              isPassword: true,
              bottom: 10,
              onChanged: (_) => setState(() {}),
              validator: (v) => (v == null || v.length < 8)
                  ? 'Use at least 8 characters.'
                  : null),
        ]),
      ),
      PasswordStrength(_pass.text),
      Align(
        alignment: Alignment.centerLeft,
        child: AuthCheck(
          value: _agree,
          onChanged: (v) => setState(() => _agree = v),
          label: Text('I agree to the Terms and Conditions',
              style: TextStyle(fontSize: 12.5, color: authMuted(context))),
        ),
      ),
      const SizedBox(height: 18),
      AuthError(_error),
      AuthButton(label: 'Create account', onPressed: _submit, loading: _loading),
      const Spacer(),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('Already have an account? ',
              style: TextStyle(fontSize: 13, color: authMuted(context))),
          AuthLink('Log in', () => Navigator.pop(context), color: kTeal),
        ]),
      ),
    ]);
  }
}