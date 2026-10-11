import 'package:flutter/material.dart';

// Shared UI pieces for the auth screens, matched to the Flowstep design.
// Colors were sampled from the design: background #F6F9FF, teal #00C0A5.
const kTeal = Color(0xFF00C0A5);
const kInk = Color(0xFF1A2233);
const kAppName = 'Pennywise'; // CHECK against the design: text was blurry
const kTagline = 'Your money, made simple'; // CHECK against the design

bool _dark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;
Color authBg(BuildContext c) =>
    _dark(c) ? const Color(0xFF0E1420) : const Color(0xFFF6F9FF);
Color authText(BuildContext c) => _dark(c) ? const Color(0xFFF2F5FA) : kInk;
Color authMuted(BuildContext c) =>
    _dark(c) ? const Color(0xFF98A2B8) : const Color(0xFF6B7385);
Color authField(BuildContext c) =>
    _dark(c) ? const Color(0xFF182032) : Colors.white;
Color authBorder(BuildContext c) =>
    _dark(c) ? const Color(0xFF263049) : const Color(0xFFE3E8F2);
Color authCard(BuildContext c) =>
    _dark(c) ? const Color(0xFF1A2335) : const Color(0xFFEAEFF7);

/// Page shell: light background, 24px side padding, scrolls on small screens.
/// Use Spacer() inside [children] to push content down or center it.
class AuthPage extends StatelessWidget {
  final List<Widget> children;
  final bool showBack;
  const AuthPage({super.key, required this.children, this.showBack = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: authBg(context),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: box.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (showBack)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          alignment: Alignment.centerLeft,
                          icon: Icon(Icons.arrow_back_ios_new,
                              size: 16, color: authText(context)),
                          onPressed: () => Navigator.maybePop(context),
                        ),
                      )
                    else
                      const SizedBox(height: 16),
                    ...children,
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

/// Teal rounded-square app icon (login) or soft mint circle icon (other screens).
class AuthIcon extends StatelessWidget {
  final IconData icon;
  final bool square;
  const AuthIcon(this.icon, {super.key, this.square = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: square ? 56 : 52,
      height: square ? 56 : 52,
      decoration: BoxDecoration(
        color: square ? kTeal : kTeal.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(square ? 16 : 26),
      ),
      child: Icon(icon, size: 26, color: square ? kInk : authText(context)),
    );
  }
}

class AuthHeading extends StatelessWidget {
  final String text;
  final TextAlign align;
  const AuthHeading(this.text, {super.key, this.align = TextAlign.left});
  @override
  Widget build(BuildContext context) => Text(text,
      textAlign: align,
      style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: authText(context)));
}

class AuthSubtitle extends StatelessWidget {
  final String text;
  final TextAlign align;
  const AuthSubtitle(this.text, {super.key, this.align = TextAlign.left});
  @override
  Widget build(BuildContext context) => Text(text,
      textAlign: align,
      style: TextStyle(fontSize: 13, color: authMuted(context)));
}

/// White field with thin border, 12px corners, label above it.
class AuthField extends StatelessWidget {
  final String? label;
  final String hint;
  final TextEditingController controller;
  final bool isPassword;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final double bottom;
  const AuthField({
    super.key,
    this.label,
    required this.hint,
    required this.controller,
    this.isPassword = false,
    this.prefixIcon,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.bottom = 14,
  });

  OutlineInputBorder _b(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: c, width: 1));

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(label!,
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: authText(context))),
            ),
          TextFormField(
            controller: controller,
            obscureText: isPassword,
            keyboardType: keyboardType,
            validator: validator,
            onChanged: onChanged,
            style: TextStyle(fontSize: 14, color: authText(context)),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(fontSize: 14, color: authMuted(context)),
              filled: true,
              fillColor: authField(context),
              prefixIcon: prefixIcon == null
                  ? null
                  : Icon(prefixIcon, size: 18, color: authMuted(context)),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
              border: _b(authBorder(context)),
              enabledBorder: _b(authBorder(context)),
              focusedBorder: _b(kTeal),
              errorBorder: _b(const Color(0xFFE5484D)),
              focusedErrorBorder: _b(const Color(0xFFE5484D)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-width 48px button: solid teal, or white outlined (with optional icon).
class AuthButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool outlined;
  final bool loading;
  final IconData? icon;
  const AuthButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.outlined = false,
    this.loading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final fg = outlined ? authText(context) : kInk;
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: Material(
        color: outlined ? authField(context) : kTeal,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: loading ? null : onPressed,
          child: Container(
            decoration: outlined
                ? BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: authBorder(context)))
                : null,
            child: Center(
              child: loading
                  ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: fg))
                  : Row(mainAxisSize: MainAxisSize.min, children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: fg),
                  const SizedBox(width: 8),
                ],
                Text(label,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: fg)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Small text link. Default is bold ink; pass [color] for teal links.
class AuthLink extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final Color? color;
  const AuthLink(this.text, this.onTap, {super.key, this.color});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Text(text,
        style: TextStyle(
            color: color ?? authText(context),
            fontWeight: FontWeight.w700,
            fontSize: 13)),
  );
}

/// Small teal checkbox with a label ("Remember me", "I agree to ...").
class AuthCheck extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget label;
  const AuthCheck(
      {super.key,
        required this.value,
        required this.onChanged,
        required this.label});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => onChanged(!value),
    behavior: HitTestBehavior.opaque,
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: value ? kTeal : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: value ? kTeal : authBorder(context), width: 1.5),
        ),
        child: value
            ? const Icon(Icons.check, size: 13, color: Colors.white)
            : null,
      ),
      const SizedBox(width: 8),
      Flexible(child: label),
    ]),
  );
}

/// "──── or ────" divider used on the login screen.
class AuthOrDivider extends StatelessWidget {
  const AuthOrDivider({super.key});
  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Divider(color: authBorder(context))),
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Text('or',
          style: TextStyle(fontSize: 12, color: authMuted(context))),
    ),
    Expanded(child: Divider(color: authBorder(context))),
  ]);
}

int passwordScore(String v) {
  var s = 0;
  if (v.length >= 8) s++;
  if (RegExp(r'[A-Z]').hasMatch(v) && RegExp(r'[a-z]').hasMatch(v)) s++;
  if (RegExp(r'\d').hasMatch(v)) s++;
  if (RegExp(r'[^A-Za-z0-9]').hasMatch(v) || v.length >= 14) s++;
  return s;
}

/// 4-segment teal strength bar with a short label under it (signup screen).
class PasswordStrength extends StatelessWidget {
  final String value;
  const PasswordStrength(this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    final s = passwordScore(value);
    final color = s >= 3
        ? kTeal
        : s == 2
        ? const Color(0xFFF5A524)
        : const Color(0xFFE5484D);
    final label = s >= 3
        ? 'Strong password'
        : s == 2
        ? 'Medium password'
        : 'Weak password';
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(
              4,
                  (i) => Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
                  decoration: BoxDecoration(
                    color: value.isNotEmpty && i < s
                        ? color
                        : authBorder(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
          if (value.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 11.5, fontWeight: FontWeight.w600, color: color)),
          ],
        ],
      ),
    );
  }
}

/// Grey rounded card listing the three password rules (new password screen).
class PasswordRules extends StatelessWidget {
  final String value;
  const PasswordRules(this.value, {super.key});

  Widget _rule(BuildContext context, String text, bool ok) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [
      Icon(ok ? Icons.check_circle : Icons.check_circle_outline,
          size: 16, color: ok ? kTeal : authMuted(context)),
      const SizedBox(width: 10),
      Text(text,
          style: TextStyle(fontSize: 12.5, color: authText(context))),
    ]),
  );

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
    decoration: BoxDecoration(
        color: authCard(context), borderRadius: BorderRadius.circular(12)),
    child: Column(children: [
      _rule(context, 'At least 8 characters', value.length >= 8),
      _rule(
          context,
          'Upper and lowercase letters',
          RegExp(r'[A-Z]').hasMatch(value) &&
              RegExp(r'[a-z]').hasMatch(value)),
      _rule(context, 'At least one number', RegExp(r'\d').hasMatch(value)),
    ]),
  );
}

/// Red message under a form when the backend returns an error.
class AuthError extends StatelessWidget {
  final String? message;
  const AuthError(this.message, {super.key});
  @override
  Widget build(BuildContext context) => message == null
      ? const SizedBox.shrink()
      : Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(message!,
        style: const TextStyle(color: Color(0xFFE5484D), fontSize: 13)),
  );
}

String? validateEmail(String? v) {
  if (v == null || v.trim().isEmpty) return 'Enter your email.';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) {
    return 'Enter a valid email, like you@example.com.';
  }
  return null;
}