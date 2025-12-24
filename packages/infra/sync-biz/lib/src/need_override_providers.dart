import 'package:app_core/di.dart';
import 'package:app_core/object.dart';
import 'package:sync_api/sync_api.dart';

part 'need_override_providers.g.dart';

@riverpod
Future<List<SyncDelegate<dynamic>>> syncDelegates(Ref ref) {
  throw NotOverrideError();
}
