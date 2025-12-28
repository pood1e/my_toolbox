import 'package:app_core/di.dart';
import 'package:app_core/object.dart';

import '../network_api.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
Future<ServerTimeService> serverTimeService(Ref ref) {
  throw NotOverrideError();
}

@Riverpod(keepAlive: true)
Future<DeviceIdService> deviceIdService(Ref ref) {
  throw NotOverrideError();
}
