import 'package:core/di.dart';
import 'package:sync_api/sync_api.dart';

part 'need_override_providers.g.dart';

@Riverpod(keepAlive: true)
Future<List<SyncDelegate<dynamic>>> syncDelegates(Ref ref) {
  throw UnimplementedError('must override');
}
