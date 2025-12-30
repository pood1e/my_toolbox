import 'package:app_core/core.dart';
import 'package:app_core/di.dart';
import 'package:app_core/route.dart';
import 'package:sync_api/sync_api.dart';

part 'feature_registry.g.dart';

class FeatureRegistry {
  List<AppDefinition> get appDefinitions => [];

  List<RouteBase> routes(Ref ref) => [];

  List<StartupAction> startups(Ref ref) => [
  ];

  Future<List<SyncDelegate>> syncDelegates(Ref ref) async {
    return [];
  }
}

@riverpod
FeatureRegistry featureRegistry(Ref ref) {
  return FeatureRegistry();
}
