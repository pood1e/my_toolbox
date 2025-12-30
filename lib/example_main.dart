import 'package:app_core/core.dart';
import 'package:framework_api/framework_api.dart';
import 'package:framework_biz/starter.dart';

import 'src/example_app_definitions.dart';

class MyToolboxFeatureRegistry extends FeatureRegistry {
  @override
  List<AppDefinition> get appDefinitions => kExampleApps;
}

void main() {
  startApp(featureRegistry: MyToolboxFeatureRegistry());
}
