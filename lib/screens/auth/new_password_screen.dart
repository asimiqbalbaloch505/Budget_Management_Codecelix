import 'package:flutter/material.dart';
import 'auth_widgets.dart';

class NewPasswordScreen extends StatefulWidget {
  /// Integration hook: returns null on success, or an error message to show.
  final Future<String?> Function(String newPassword)? onSave;
  /// Called after a successful save. Defaults to going back to the login screen.
  final VoidCallback? onSuccess;
  const NewPasswordScreen({super.key, this.onSave, this.onSuccess});
  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _pass = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _pass.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final err = await widget.onSave?.call(_pass.text);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = err;
    });
    if (err != null) return;
    if (widget.onSuccess != null) {
      widget.onSuccess!();
    } else {
      Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPage(children: [
      const SizedBox(height: 40),
      const AuthHeading('Create a new password'),
      const SizedBox(height: 6),
      const AuthSubtitle('Choose a strong password to secure your account.'),
      const SizedBox(height: 24),
      Form(
        key: _form,
        child: AuthField(
            label: 'New password',
            hint: 'Enter your new password',
            controller: _pass,
            isPassword: true,
            prefixIcon: Icons.lock_outline,
            onChanged: (_) => setState(() {}),
            validator: (v) {
              final s = v ?? '';
              if (s.length < 8 ||
                  !RegExp(r'[A-Z]').hasMatch(s) ||
                  !RegExp(r'[a-z]').hasMatch(s) ||
                  !RegExp(r'\d').hasMatch(s)) {
                return 'Please meet all the password rules below.';
              }
              return null;
            }),
      ),
      PasswordRules(_pass.text),
      const Spacer(),
      const SizedBox(height: 20),
      AuthError(_error),
      AuthButton(label: 'Update password', onPressed: _save, loading: _loading),
      const SizedBox(height: 10),
      Center(
          child: Text("You'll log in again after updating.",
              style: TextStyle(fontSize: 11, color: authMuted(context)))),
      const SizedBox(height: 16),
    ]);
  }
}