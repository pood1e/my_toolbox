import 'package:app_core/di.dart';

import '../data/dao_providers.dart';
import '../feature_registry.dart';
import 'impl/launcher_service_impl.dart';
import 'launcher_service.dart';

part 'service_providers.g.dart';

@riverpod
Future<LauncherService> launcherService(Ref ref) async {
  final apps = ref.read(featureRegistryProvider).appDefinitions;
  return LauncherServiceImpl(
    allApps: apps,
    dao: await ref.watch(launcherDaoProvider.future),
  );
}
