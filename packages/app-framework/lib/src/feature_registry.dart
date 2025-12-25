import 'package:app_core/core.dart';
import 'package:app_core/di.dart';
import 'package:app_core/route.dart';

part 'feature_registry.g.dart';

class FeatureRegistry {
  List<AppDefinition> get appDefinitions => [];

  List<RouteBase> get routes => [];

  List<StartupAction> get startups => [];
}

@riverpod
FeatureRegistry featureRegistry(Ref ref) {
  return FeatureRegistry();
}
