import 'package:findme/core/config/app_config.dart';
import 'package:findme/core/errors/app_errors.dart';
import 'package:findme/core/theme/palette.dart';
import 'package:findme/core/widgets/card_box.dart';
import 'package:findme/core/widgets/pill.dart';
import 'package:findme/features/auth/data/auth_repository.dart';
import 'package:findme/features/auth/presentation/auth_controller.dart';
import 'package:findme/features/bag/presentation/bag_sheet.dart'
    show linkOpenerProvider;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// The web says "go to /admin"; the app has no admin page, so it points to the web.
const noAccountText =
    'Tài khoản này chưa dùng được bản đồ. Đây có thể là tài khoản admin: hãy quản trị trên trang web /admin.';

/// The welcome card: starting up, sign-in form, or "this login has no map" (the web's App.tsx welcome).
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 96,
                      height: 96,
                    ),
                  ),
                  const SizedBox(height: 8),
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
                  const SizedBox(height: 16),
                  if (phase == AuthPhase.signedOut) const SignInForm(),
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
                  // The web's SignIn.tsx link; the App Store and Play want the policy reachable in the app.
                  // ponytail: only here (signed out); add it to a settings screen too once one exists.
                  TextButton(
                    onPressed: () => ref.read(linkOpenerProvider)(
                      Uri.parse(
                        '${ref.read(appConfigProvider).web}/privacy.html',
                      ),
                    ),
                    child: const Text(
                      'Chính sách quyền riêng tư',
                      style: TextStyle(color: Palette.muted, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _Mode { signin, register, verify }

/// Email + password, sent straight to Cognito. AutofillGroup lets password managers save and fill it. Also self
/// sign-up (the web's `SignIn register`): name + invite code, then the 6-digit code from the email, then signed in
/// at once (the password is still in the form).
class SignInForm extends ConsumerStatefulWidget {
  const SignInForm({super.key});

  @override
  ConsumerState<SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends ConsumerState<SignInForm> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _invite = TextEditingController();
  final _code = TextEditingController();
  _Mode _mode = _Mode.signin;
  bool _busy = false;
  String _err = '';
  String _note = '';

  @override
  void dispose() {
    for (final c in [_email, _password, _name, _invite, _code]) {
      c.dispose();
    }
    super.dispose();
  }

  void _go(_Mode m) => setState(() {
    _mode = m;
    _err = '';
    _note = '';
  });

  Future<void> _run(Future<void> Function() f) async {
    setState(() {
      _busy = true;
      _err = '';
      _note = '';
    });
    try {
      await f();
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        if (e is AuthError && e.code == 'UserNotConfirmedException') {
          _mode = _Mode.verify;
        }
        _err = signInMessage(e);
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signIn() async {
    await ref
        .read(authControllerProvider.notifier)
        .signIn(_email.text, _password.text);
    TextInput.finishAutofillContext();
  }

  Future<void> _submit() {
    // The web's `required` inputs: nothing goes out with an empty field.
    final need = switch (_mode) {
      _Mode.signin => [_email, _password],
      _Mode.register => [_name, _email, _password, _invite],
      _Mode.verify => [_email, _code],
    };
    if (need.any((c) => c.text.trim().isEmpty)) return Future.value();
    final auth = ref.read(authRepositoryProvider);
    return switch (_mode) {
      _Mode.signin => _run(_signIn),
      _Mode.register => _run(() async {
        try {
          await auth.signUp(
            _email.text,
            _password.text,
            _name.text,
            _invite.text,
          );
        } on AuthError catch (e) {
          if (e.code == 'UsernameExistsException') _mode = _Mode.verify;
          rethrow;
        }
        setState(() {
          _mode = _Mode.verify;
          _note = 'Đã gửi mã 6 số tới email của bạn 💌';
        });
      }),
      _Mode.verify => _run(() async {
        await auth.confirmSignUp(_email.text, _code.text);
        if (_password.text.isNotEmpty) {
          await _signIn(); // straight in
          return;
        }
        setState(() {
          _mode = _Mode.signin;
          _note = 'Xác nhận xong! Đăng nhập nhé 💖';
        });
      }),
    };
  }

  Future<void> _resend() => _run(() async {
    await ref.read(authRepositoryProvider).resendCode(_email.text);
    setState(() => _note = 'Đã gửi lại mã 💌');
  });

  @override
  Widget build(BuildContext context) => AutofillGroup(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_mode == _Mode.register) ...[
          TextField(
            key: const Key('name'),
            controller: _name,
            maxLength: 40,
            autofillHints: const [AutofillHints.nickname],
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              hintText: 'Tên của bạn',
              counterText: '',
            ),
          ),
          const SizedBox(height: 10),
        ],
        TextField(
          key: const Key('email'),
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          autofillHints: const [AutofillHints.username, AutofillHints.email],
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(hintText: 'Email'),
        ),
        if (_mode != _Mode.verify) ...[
          const SizedBox(height: 10),
          TextField(
            key: const Key('password'),
            controller: _password,
            obscureText: true,
            autofillHints: [
              if (_mode == _Mode.register)
                AutofillHints.newPassword
              else
                AutofillHints.password,
            ],
            textInputAction: _mode == _Mode.register
                ? TextInputAction.next
                : TextInputAction.done,
            onSubmitted: _mode == _Mode.signin ? (_) => _submit() : null,
            decoration: const InputDecoration(hintText: 'Mật khẩu'),
          ),
        ],
        if (_mode == _Mode.register) ...[
          const SizedBox(height: 10),
          TextField(
            key: const Key('invite'),
            controller: _invite,
            autocorrect: false,
            onSubmitted: (_) => _submit(),
            decoration: const InputDecoration(hintText: 'Mã mời'),
          ),
        ],
        if (_mode == _Mode.verify) ...[
          const SizedBox(height: 10),
          TextField(
            key: const Key('code'),
            controller: _code,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            autofillHints: const [AutofillHints.oneTimeCode],
            onSubmitted: (_) => _submit(),
            decoration: const InputDecoration(
              hintText: 'Mã 6 số trong email',
              counterText: '',
            ),
          ),
        ],
        if (_note.isNotEmpty) ...[const SizedBox(height: 10), Notice(_note)],
        if (_err.isNotEmpty) ...[
          const SizedBox(height: 10),
          Notice(_err, error: true),
        ],
        const SizedBox(height: 10),
        Pill(
          label: _busy
              ? 'Đợi chút…'
              : switch (_mode) {
                  _Mode.signin => 'Đăng nhập 💖',
                  _Mode.register => 'Tạo tài khoản ✨',
                  _Mode.verify => 'Xác nhận 💌',
                },
          style: PillStyle.on,
          onTap: _busy ? null : _submit,
        ),
        if (_mode == _Mode.verify) ...[
          const SizedBox(height: 8),
          Pill(label: 'Gửi lại mã', onTap: _busy ? null : _resend),
        ],
        const SizedBox(height: 8),
        if (_mode == _Mode.signin)
          Pill(
            label: 'Chưa có tài khoản? Đăng ký',
            onTap: () => _go(_Mode.register),
          )
        else
          Pill(label: 'Quay lại đăng nhập', onTap: () => _go(_Mode.signin)),
      ],
    ),
  );
}
