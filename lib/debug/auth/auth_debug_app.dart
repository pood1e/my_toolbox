import 'package:auth_ui/ui.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

void main() {
  // 必须使用 ProviderScope 包裹应用
  runApp(ProviderScope(child: AuthDebugApp()));
}

class AuthDebugApp extends ConsumerWidget {
  const AuthDebugApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 获取我们在 app_router.dart 中定义的 router
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Flutter Auth Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      // 将 GoRouter 配置给 MaterialApp
      routerConfig: router,
      // --- 关键点：在此处注入全局 Banner ---
      builder: (context, child) {
        // child 是 Navigator (即当前的页面)
        // 我们用 Banner 包裹它
        return GlobalConnectionBanner(child: child ?? const SizedBox.shrink());
      },
    );
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/', // 直接进入调试页
    routes: [
      // 根路径：调试页
      GoRoute(
        path: '/',
        builder: (context, state) => DebugPage(
          // 动作：去登陆页
          onGoLogin: () => context.push('/login'),
          // 动作：去注册页
          onGoRegister: () => context.push('/register'),
        ),
      ),

      // 登陆页
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginPage(
          // 登陆成功：返回调试页查看结果
          onLoginSuccess: () => context.pop(),
          // 去注册：替换当前页
          onGoToRegister: () => context.pushReplacement('/register'),
        ),
      ),

      // 注册页
      GoRoute(
        path: '/register',
        builder: (context, state) => RegisterPage(
          // 注册成功：返回调试页查看结果
          onRegisterSuccess: () => context.pop(),
        ),
      ),
    ],
  );
});
