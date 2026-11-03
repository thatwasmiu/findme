import 'package:findme/core/theme/palette.dart';
import 'package:findme/core/widgets/card_box.dart';
import 'package:findme/core/widgets/pill.dart';
import 'package:findme/features/auth/data/auth_repository.dart';
import 'package:findme/features/auth/presentation/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// The web says "go to /admin"; the app has no admin page, so it points to the web.
const noAccountText =
    'Tài khoản này chưa dùng được bản đồ. Đây có thể là tài khoản admin: hãy quản trị trên trang web /admin.';

/// The welcome card: starting up, sign-in form, or "this login has no map" (the web's App.tsx welcome).
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key, this.error});

  /// A startup problem to show (e.g. missing config).
  final String? error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase = ref.watch(authControllerProvider);
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: CardBox(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('📍', style: TextStyle(fontSize: 48)),
                  const Text(
                    'Find Me',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    phase == AuthPhase.loading ? 'Đang khởi động…' : 'Mọi nơi bạn đã đi qua, gói gọn trong một tấm bản đồ xinh xắn.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Palette.muted),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Notice(error!, error: true),
                  ],
                  const SizedBox(height: 16),
                  if (phase == AuthPhase.signedOut && error == null)
                    const SignInForm(),
                  if (phase == AuthPhase.noAccount) ...[
                    const Notice(noAccountText, error: true),
                    const SizedBox(height: 12),
                    Pill(
                      label: 'Đăng xuất',
                      style: PillStyle.on,
                      onTap: () =>
                          ref.read(authControllerProvider.notifier).signOut(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Email + password, sent straight to Cognito. AutofillGroup lets password managers save and fill it.
class SignInForm extends ConsumerStatefulWidget {
  const SignInForm({super.key});

  @override
  ConsumerState<SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends ConsumerState<SignInForm> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String _err = '';

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_email.text.trim().isEmpty || _password.text.isEmpty) return;
    setState(() {
      _busy = true;
      _err = '';
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .signIn(_email.text, _password.text);
      TextInput.finishAutofillContext();
    } on Object catch (e) {
      if (mounted) setState(() => _err = signInMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AutofillGroup(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('email'),
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          autofillHints: const [AutofillHints.username, AutofillHints.email],
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(hintText: 'Email'),
        ),
        const SizedBox(height: 10),
        TextField(
          key: const Key('password'),
          controller: _password,
          obscureText: true,
          autofillHints: const [AutofillHints.password],
          onSubmitted: (_) => _submit(),
          decoration: const InputDecoration(hintText: 'Mật khẩu'),
        ),
        if (_err.isNotEmpty) ...[
          const SizedBox(height: 10),
          Notice(_err, error: true),
        ],
        const SizedBox(height: 10),
        Pill(
          label: _busy ? 'Đang đăng nhập…' : 'Đăng nhập 💖',
          style: PillStyle.on,
          onTap: _busy ? null : _submit,
        ),
      ],
    ),
  );
}
