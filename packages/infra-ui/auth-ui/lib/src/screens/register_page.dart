import 'package:auth_biz/auth_biz.dart';
import 'package:common_ui/message.dart';
import 'package:core/di.dart';
import 'package:flutter/material.dart';

import '../components/auth_text_field.dart';
import '../components/error_message.dart';
import '../components/server_config_panel.dart';

class RegisterPage extends ConsumerStatefulWidget {
  /// 注册并登陆成功后的回调
  final VoidCallback onRegisterSuccess;

  const RegisterPage({super.key, required this.onRegisterSuccess});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  // ... Controller 初始化 ...
  final _hostController = TextEditingController(text: '127.0.0.1');
  final _portController = TextEditingController(text: '8080');
  final _emailController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _passController = TextEditingController();
  final _tlsNotifier = ValueNotifier<bool>(false);

  bool _isLoading = false;

  // ... dispose 省略 ...

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // 1. 调用业务
      final service = await ref.read(authServiceProvider.future);

      await service.register(
        host: _hostController.text,
        port: int.parse(_portController.text),
        tls: _tlsNotifier.value,
        email: _emailController.text,
        nickname: _nicknameController.text,
        pass: _passController.text,
      );

      // 2. 成功提示
      if (mounted) {
        SnackbarService.showSuccess('注册成功，已自动登录');
        // 3. 触发成功回调
        widget.onRegisterSuccess();
      }
    } catch (e) {
      if (mounted) {
        SnackbarService.showError(getAuthErrorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('注册新用户')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                children: [
                  ServerConfigPanel(
                    hostController: _hostController,
                    portController: _portController,
                    tlsNotifier: _tlsNotifier,
                  ),
                  AuthTextField(
                    controller: _emailController,
                    label: 'Email',
                    icon: Icons.email,
                  ),
                  AuthTextField(
                    controller: _nicknameController,
                    label: 'Nickname',
                    icon: Icons.badge,
                  ),
                  AuthTextField(
                    controller: _passController,
                    label: 'Password',
                    icon: Icons.lock,
                    obscureText: true,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('注册'),
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
