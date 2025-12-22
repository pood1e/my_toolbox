import 'package:core/di.dart';
import 'package:core/object.dart';

import 'sync_service.dart';

part 'service_providers.g.dart';

@Riverpod(keepAlive: true)
Future<SyncService> syncService(Ref ref) async {
  throw NotOverrideError();
}
