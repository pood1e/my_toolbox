import 'package:app_core/di.dart';
import 'package:app_core/object.dart';
import 'package:data_api/data_api.dart';

part 'need_override_providers.g.dart';

@riverpod
Future<List<Migratable<dynamic>>> migrations(Ref ref) {
  throw NotOverrideError();
}
