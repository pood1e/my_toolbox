import 'package:app_core/di.dart';
import 'package:app_core/object.dart';

import 'domain/sync_action.dart';
import 'standard/sync_standard_api.dart';

part 'providers.g.dart';

@riverpod
Future<bool> autoSyncEnabled(Ref ref) {
  throw NotOverrideError();
}

@Riverpod(keepAlive: true)
SyncAction syncAction(Ref ref) {
  throw NotOverrideError();
}

@riverpod
Future<SyncStandardApi<T>> syncStandardApi<T>(
  Ref ref,
  String apiPath,
  FromJson<T> fromJson,
  ToJson<T> toJson,
) {
  throw NotOverrideError();
}
