import 'package:flutter/material.dart';
import 'auth_widgets.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  /// Integration hooks (wired later by the integration intern with Provider).
  /// onLogin returns null on success, or an error message to show.
  final Future<String?> Function(String email, String password)? onLogin;
  final VoidCallback? onSuccess; // e.g. go to the dashboard
  const LoginScreen({super.key, this.onLogin, this.onSuccess});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _keep = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final err = await widget.onLogin?.call(_email.text.trim(), _pass.text);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = err;
    });
    if (err == null) widget.onSuccess?.call();
  }

  @override
  Widget build(BuildContext context) {
    return AuthPage(children: [
      const SizedBox(height: 32),
      const Center(child: AuthIcon(Icons.account_balance_wallet_outlined, square: true)),
      const SizedBox(height: 12),
      Center(
          child: Text(kAppName,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: authText(context)))),
      const SizedBox(height: 4),
      const Center(child: AuthSubtitle(kTagline)),
      const SizedBox(height: 28),
      const AuthHeading('Welcome back'),
      const SizedBox(height: 20),
      Form(
        key: _form,
        child: Column(children: [
          AuthField(
              label: 'Email',
              hint: 'you@example.com',
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              validator: validateEmail),
          AuthField(
              label: 'Password',
              hint: 'Enter your password',
              controller: _pass,
              isPassword: true,
              bottom: 12,
              validator: (v) =>
              (v == null || v.isEmpty) ? 'Enter your password.' : null),
        ]),
      ),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        AuthCheck(
          value: _keep,
          onChanged: (v) => setState(() => _keep = v),
          label: Text('Remember me',
              style: TextStyle(fontSize: 12.5, color: authMuted(context))),
        ),
        AuthLink(
            'Forgot password?',
                () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ForgotPasswordScreen()))),
      ]),
      const SizedBox(height: 16),
      AuthError(_error),
      AuthButton(label: 'Log in', onPressed: _submit, loading: _loading),
      const SizedBox(height: 16),
      const AuthOrDivider(),
      const SizedBox(height: 16),
      AuthButton(
          label: 'Continue with Apple',
          icon: Icons.apple,
          outlined: true,
          onPressed: () {}),
      const Spacer(),
      Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('New to $kAppName? ',
              style: TextStyle(fontSize: 13, color: authMuted(context))),
          AuthLink(
              'Sign up',
                  () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SignupScreen()))),
        ]),
      ),
      const SizedBox(height: 12),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.lock_outline, size: 12, color: authMuted(context)),
        const SizedBox(width: 4),
        Text('Your information is kept secure',
            style: TextStyle(fontSize: 11, color: authMuted(context))),
      ]),
      const SizedBox(height: 12),
    ]);
  }
}