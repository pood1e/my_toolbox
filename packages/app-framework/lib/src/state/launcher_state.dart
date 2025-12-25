import 'package:app_core/core.dart';
import 'package:app_core/di.dart';

import '../feature_registry.dart';
import '../service/service_providers.dart';

part 'launcher_state.g.dart';

@riverpod
class LauncherEntryNotifier extends _$LauncherEntryNotifier {
  @override
  Stream<List<AppDefinition>> build() async* {
    yield ref.read(featureRegistryProvider).appDefinitions;
    final service = await ref.watch(launcherServiceProvider.future);
    yield* service.watchApps();
  }
}
