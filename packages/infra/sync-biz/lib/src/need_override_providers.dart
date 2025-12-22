import 'package:core/di.dart';
import 'package:core/object.dart';
import 'package:sync_api/sync_api.dart';

@Riverpod(keepAlive: true)
Future<List<SyncDelegate<dynamic>>> syncDelegatesRegistry(Ref ref) {
  throw NotOverrideError();
}
