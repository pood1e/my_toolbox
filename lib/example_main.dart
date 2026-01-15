import 'package:app_core/core.dart';
import 'package:app_core/di.dart';
import 'package:app_core/route.dart';
import 'package:event_api/event_api.dart';
import 'package:event_biz/event_biz.dart';
import 'package:framework_api/framework_api.dart';
import 'package:framework_biz/starter.dart';
import 'package:memo_biz/memo_biz.dart';
import 'package:pomodoro_biz/pomodoro_biz.dart';

import 'src/example_app_definitions.dart';

class MyToolboxFeatureRegistry extends FeatureRegistry {
  @override
  List<AppDefinition> get appDefinitions => kExampleApps;

  @override
  List<RouteBase> routes(Ref ref) => [
    ...ref.read(eventRoutesProvider),
    ...ref.read(memoRoutesProvider),
    ...ref.read(pomodoroRoutesProvider),
  ];

  @override
  Future<List<SyncDelegate>> syncDelegates(Ref ref) async {
    return [
      await ref.read(eventSyncDelegateProvider.future),
      await ref.read(memoSyncDelegateProvider.future),
      await ref.read(pomodoroSyncDelegateProvider.future),
    ];
  }
}

void main() {
  startApp(
    featureRegistry: MyToolboxFeatureRegistry(),
    featureOverrides: [
      eventServiceProvider.overrideWith(EventApiOverride.eventService),
    ],
  );
}
