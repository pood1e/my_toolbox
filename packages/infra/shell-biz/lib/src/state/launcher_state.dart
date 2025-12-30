import 'package:app_core/core.dart';
import 'package:app_core/di.dart';
import 'package:framework_api/framework_api.dart';

import '../service/service_providers.dart';

part 'launcher_state.g.dart';

@riverpod
class AppEntrancesNotifier extends _$AppEntrancesNotifier {
  @override
  Stream<List<AppDefinition>> build() async* {
    yield ref.read(featureRegistryProvider).appDefinitions;
    final service = await ref.watch(launcherServiceProvider.future);
    yield* service.watchApps();
  }
}
