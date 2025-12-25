import 'package:app_core/di.dart';
import 'package:app_core/route.dart';

import 'feature_registry.dart';
import 'framework_registry.dart';

part 'framework_providers.g.dart';

@riverpod
Future<void> startup(Ref ref) async {
  final featureRegistry = ref.read(featureRegistryProvider);
  final frameworkRegistry = ref.read(frameworkRegistryProvider);
  final actions = [...frameworkRegistry.startups, ...featureRegistry.startups];
  await Future.wait(actions.map((action) async => action()));
}

@riverpod
GoRouter appRouter(Ref ref) {
  final featureRegistry = ref.read(featureRegistryProvider);
  final frameworkRegistry = ref.read(frameworkRegistryProvider);
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.home,
    routes: [...frameworkRegistry.routes, ...featureRegistry.routes],
  );
}
