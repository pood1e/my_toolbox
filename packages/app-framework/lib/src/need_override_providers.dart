import 'package:app_core/di.dart';
import 'package:app_core/route.dart';

import 'domain/app_definition.dart';
import 'override_definition.dart';

part 'need_override_providers.g.dart';

@riverpod
List<AppDefinition> appDefinitions(Ref ref) {
  return [];
}

@riverpod
List<GoRoute> routes(Ref ref) {
  return [];
}

@riverpod
List<StartupAction> startupActions(Ref ref) {
  return [];
}

@Riverpod(keepAlive: true)
Future<void> startup(Ref ref) async {
  final actions = ref.read(startupActionsProvider);
  await Future.wait(actions.map((action) async => action(ref)));
}
