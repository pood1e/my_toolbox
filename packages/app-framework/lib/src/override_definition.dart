import 'package:app_core/di.dart';
import 'package:app_core/route.dart';
import 'package:auth_biz/auth_biz.dart';
import 'package:data_biz/data_biz.dart';
import 'package:flutter/material.dart';
import 'package:sync_api/sync_api.dart';

import 'data/dao_providers.dart';
import 'data/sync/launcher_sync_delegate.dart';
import 'domain/app_definition.dart';

typedef StartupAction = Future<void> Function(Ref);

class OverrideDefinition {
  List<AppDefinition> get appDefinitions => [];

  List<GoRoute> get routes => [
    GoRoute(
      path: '/login',
      builder: (ctx, _) => LoginPage(
        onLoginSuccess: () {
          ctx.pop();
        },
        onGoToRegister: () {
          Navigator.of(ctx).popUntil((route) => route.isFirst);
        },
      ),
    ),
  ];

  List<StartupAction> get startupActions => [
    (ref) async {
      final tokenService = await ref.read(tokenServiceProvider.future);
      await tokenService.checkTokenValidation();
    },
  ];

  Future<List<SyncDelegate<dynamic>>> getSyncDelegates(Ref ref) async {
    final dio = await ref.read(authenticatedDioProvider.future);
    return [
      LauncherSyncDelegate(
        dio: dio,
        daoGetter: () async {
          return await ref.read(launcherDaoProvider.future);
        },
      ),
    ];
  }

  List<Migratable<dynamic>> get migratables => [];

  List<BeforeLogin> get beforeLogins => [];

  List<AfterLogin> get afterLogins => [];

  List<BeforeLogout> get beforeLogouts => [];

  List<AfterLogout> get afterLogouts => [];
}
