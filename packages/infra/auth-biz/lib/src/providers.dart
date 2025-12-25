/// 提供给框架使用
library;

import 'package:app_core/core.dart';
import 'package:app_core/di.dart';
import 'package:app_core/route.dart';
import 'package:flutter/material.dart';

import '../auth_biz.dart';
import 'service/service_provider.dart';
import 'state/auth_state_notifier.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
Future<String?> authenciatedAccessToken(Ref ref) async {
  final availability = ref.watch(connectionAvailabiltyProvider);
  if (availability != ConnectionAvailability.active) {
    return null;
  }
  return await ref.watch(accessTokenProvider.future);
}

@Riverpod(keepAlive: true)
StartupAction checkTokenAction(Ref ref) {
  return () async {
    final tokenService = await ref.read(tokenServiceProvider.future);
    await tokenService.checkTokenValidation();
  };
}

@Riverpod(keepAlive: true)
Future<void> Function() refreshAccessToken(Ref ref) {
  return () async {
    final tokenService = await ref.read(tokenServiceProvider.future);
    await tokenService.refresh();
  };
}

@riverpod
List<RouteBase> authRoutes(Ref ref) {
  return [
    GoRoute(
      path: AppRoutes.login,
      builder: (ctx, _) => LoginPage(
        onLoginSuccess: () {
          if (ctx.canPop()) {
            ctx.pop();
          }
        },
        onGoToRegister: () {
          ctx.push(AppRoutes.register);
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.register,
      builder: (ctx, _) => RegisterPage(
        onRegisterSuccess: () {
          if (ctx.canPop()) {
            Navigator.of(ctx).popUntil((route) => route.isFirst);
          }
        },
      ),
    ),
  ];
}
