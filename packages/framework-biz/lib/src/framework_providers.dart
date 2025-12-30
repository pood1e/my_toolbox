import 'package:app_core/di.dart';
import 'package:app_core/route.dart';
import 'package:framework_api/framework_api.dart';

import 'domain/framework_registry.dart';

part 'framework_providers.g.dart';

@riverpod
Future<void> startup(Ref ref) async {
  final featureRegistry = ref.read(featureRegistryProvider);
  final frameworkRegistry = ref.read(frameworkRegistryProvider);
  final actions = [
    ...frameworkRegistry.startups(ref),
    ...featureRegistry.startups(ref),
  ];
  await Future.wait(actions.map((action) async => action()));
}

@riverpod
GoRouter appRouter(Ref ref) {
  final featureRegistry = ref.read(featureRegistryProvider);
  final frameworkRegistry = ref.read(frameworkRegistryProvider);
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.home,
    routes: [...frameworkRegistry.routes(ref), ...featureRegistry.routes(ref)],
  );
}
