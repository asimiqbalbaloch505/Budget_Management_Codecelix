import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'auth_widgets.dart';
import 'new_password_screen.dart';

class OtpScreen extends StatefulWidget {
  final String email;
  const OtpScreen({super.key, required this.email});
  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _ctrls = List.generate(6, (_) => TextEditingController());
  final _nodes = List.generate(6, (_) => FocusNode());
  int _left = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _left = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_left == 0) {
        t.cancel();
      } else {
        setState(() => _left--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _ctrls) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _verify() {
    final code = _ctrls.map((c) => c.text).join();
    if (code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter all 6 digits of the code.')));
      return;
    }
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const NewPasswordScreen()));
  }

  Widget _box(int i) => Expanded(
    child: Padding(
      padding: EdgeInsets.only(right: i < 5 ? 8 : 0),
      child: TextField(
        controller: _ctrls[i],
        focusNode: _nodes[i],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: authText(context)),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: authField(context),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: authBorder(context))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: kTeal, width: 1.5)),
        ),
        onChanged: (v) {
          if (v.isNotEmpty && i < 5) _nodes[i + 1].requestFocus();
          if (v.isEmpty && i > 0) _nodes[i - 1].requestFocus();
        },
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final mm = '00:${_left.toString().padLeft(2, '0')}';
    return AuthPage(children: [
      const Spacer(flex: 3),
      const AuthHeading('Check your inbox', align: TextAlign.center),
      const SizedBox(height: 8),
      Text.rich(
        TextSpan(
          style: TextStyle(fontSize: 12.5, color: authMuted(context)),
          children: [
            const TextSpan(text: 'We sent a verification code to '),
            TextSpan(
                text: widget.email,
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: authText(context))),
          ],
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 26),
      Row(children: List.generate(6, _box)),
      const SizedBox(height: 22),
      AuthButton(label: 'Verify code', onPressed: _verify),
      const SizedBox(height: 14),
      Center(
        child: _left > 0
            ? Text('Resend code in $mm',
            style: TextStyle(fontSize: 11.5, color: authMuted(context)))
            : AuthLink('Resend code', () => setState(_startTimer), color: kTeal),
      ),
      const Spacer(flex: 4),
      Center(
          child: Text('Never share this code with anyone',
              style: TextStyle(fontSize: 11, color: authMuted(context)))),
      const SizedBox(height: 16),
    ]);
  }
}