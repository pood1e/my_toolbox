import 'package:app_core/core.dart';
import 'package:app_core/di.dart';
import 'package:app_core/route.dart';

import 'service/service_providers.dart';
import 'ui/pages/sync_settings_page.dart';

part 'providers.g.dart';

@riverpod
StartupAction checkRealtimeSync(Ref ref) {
  return () async {
    await ref.read(realtimeServiceProvider.future);
  };
}

@riverpod
GoRoute syncSettingsRoute(Ref ref) {
  return GoRoute(
    path: AppRoutes.syncSettingsPart,
    builder: (_, _) => SyncSettingsPage(),
  );
}
