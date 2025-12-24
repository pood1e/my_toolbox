import 'package:app_core/core.dart';
import 'package:app_framework/starter.dart';

import 'example_app_definitions.dart';

class MyToolboxFeatureRegistry extends FeatureRegistry {
  @override
  List<AppDefinition> get appDefinitions => kExampleApps;
}

void main() {
  startApp(featureRegistry: MyToolboxFeatureRegistry());
}
