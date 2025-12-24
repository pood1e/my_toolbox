import 'package:core/di.dart';
import 'package:sync_api/sync_api.dart';

import 'service/service_providers.dart';

Future<SyncService> overrideSyncService(Ref ref) async {
  return await ref.watch(syncServiceImplProvider.future);
}
