import 'package:app_core/core.dart';
import 'package:app_core/di.dart';
import 'package:app_core/route.dart';

import 'service/service_providers.dart';
import 'state/sync_settings_state.dart';
import 'ui/pages/sync_settings_page.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
StartupAction checkRealtimeSync(Ref ref) {
  return () async {
    final realtimeSyncEnabled = await ref.watch(
      realtimeSyncEnabledProvider.future,
    );
    if(realtimeSyncEnabled){
      await ref.watch(realtimeServiceProvider.future);
    }
  };
}

@riverpod
GoRoute syncSettingsRoute(Ref ref) {
  return GoRoute(
    path: AppRoutes.syncSettingsPart,
    builder: (_, _) => SyncSettingsPage(),
  );
}
