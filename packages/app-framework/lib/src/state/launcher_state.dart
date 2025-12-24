import 'package:app_core/di.dart';

import '../domain/app_definition.dart';
import '../need_override_providers.dart';
import '../service/service_providers.dart';

part 'launcher_state.g.dart';

@Riverpod(keepAlive: true)
class LauncherEntryNotifier extends _$LauncherEntryNotifier {
  @override
  Stream<List<AppDefinition>> build() async* {
    yield ref.read(appDefinitionsProvider);
    final service = await ref.read(launcherServiceProvider.future);
    yield* service.watchApps();
  }
}
