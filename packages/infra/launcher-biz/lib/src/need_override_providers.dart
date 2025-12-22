import 'package:core/di.dart';
import 'package:core/object.dart';

import 'domain/app_definition.dart';

part 'need_override_providers.g.dart';

@Riverpod(keepAlive: true)
List<AppDefinition> appDefinitions(Ref ref) {
  throw NotOverrideError();
}
