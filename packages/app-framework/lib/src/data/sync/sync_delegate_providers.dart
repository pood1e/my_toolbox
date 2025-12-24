import 'package:app_core/di.dart';
import 'package:sync_api/sync_api.dart';

import '../dao_providers.dart';
import '../launcher/launcher_dto.dart';
import 'launcher_sync_delegate.dart';

part 'sync_delegate_providers.g.dart';

@riverpod
Future<LauncherSyncDelegate> launcherSyncDelegate(Ref ref) async {
  final api = await ref.read(
    syncStandardApiProvider(
      '/settings/launcher',
      LauncherSyncPayload.fromJson,
      (t) => t.toJson(),
    ).future,
  );
  return LauncherSyncDelegate(
    api: api,
    daoGetter: () async {
      return await ref.read(launcherDaoProvider.future);
    },
  );
}
