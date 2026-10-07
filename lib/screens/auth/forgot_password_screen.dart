import 'package:flutter/material.dart';
import 'auth_widgets.dart';
import 'otp_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _send() {
    if (!_form.currentState!.validate()) return;
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => OtpScreen(email: _email.text.trim())));
  }

  @override
  Widget build(BuildContext context) {
    return AuthPage(children: [
      const Spacer(),
      const Center(child: AuthIcon(Icons.home_outlined)),
      const SizedBox(height: 16),
      const AuthHeading('Forgot your password?', align: TextAlign.center),
      const SizedBox(height: 22),
      Form(
        key: _form,
        child: AuthField(
            hint: 'aarav@example.com',
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            validator: validateEmail,
            bottom: 12),
      ),
      AuthButton(label: 'Send code', onPressed: _send),
      const SizedBox(height: 12),
      const AuthSubtitle("We'll email you a 6-digit code.",
          align: TextAlign.center),
      const SizedBox(height: 20),
      Center(child: AuthLink('Back to login', () => Navigator.pop(context))),
      const Spacer(),
    ]);
  }
}