import 'package:auth_biz/auth_biz.dart';
import 'package:common_ui/message.dart';
import 'package:core/di.dart';
import 'package:flutter/material.dart';

import '../components/auth_text_field.dart';
import '../components/error_message.dart';
import '../components/server_config_panel.dart';

class LoginPage extends ConsumerStatefulWidget {
  /// 登陆成功后的回调 (通常用于路由跳转)
  final VoidCallback onLoginSuccess;

  /// 点击"去注册"的回调
  final VoidCallback onGoToRegister;

  const LoginPage({
    super.key,
    required this.onLoginSuccess,
    required this.onGoToRegister,
  });

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final _hostController = TextEditingController(text: '127.0.0.1');
  final _portController = TextEditingController(text: '8080');
  final _emailController = TextEditingController(text: 'xx@gmail.com');
  final _passController = TextEditingController(text: 'xxxxxx');
  final _tlsNotifier = ValueNotifier<bool>(false);

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _emailController.dispose();
    _passController.dispose();
    _tlsNotifier.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      // 1. 组件自己负责调用业务逻辑
      final service = await ref.read(authServiceProvider.future);
      await service.login(
        host: _hostController.text,
        port: int.parse(_portController.text),
        tls: _tlsNotifier.value,
        email: _emailController.text,
        pass: _passController.text,
      );

      // 2. 只有业务执行成功，才触发回调
      if (mounted) {
        SnackbarService.showSuccess('登录成功'); // 全局 SnackBar
        widget.onLoginSuccess();
      }
    } catch (e) {
      // 3. 错误处理留在组件内部
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
      appBar: AppBar(title: const Text('系统登陆')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ServerConfigPanel(
                    hostController: _hostController,
                    portController: _portController,
                    tlsNotifier: _tlsNotifier,
                  ),
                  AuthTextField(
                    controller: _emailController,
                    label: '邮箱',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v!.contains('@') ? null : '邮箱格式不正确',
                  ),
                  AuthTextField(
                    controller: _passController,
                    label: '密码',
                    icon: Icons.lock,
                    obscureText: true,
                    validator: (v) => v!.length < 6 ? '密码不能少于6位' : null,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('登 陆'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: widget.onGoToRegister, // 点击直接回调
                    child: const Text('没有账号？立即注册'),
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
