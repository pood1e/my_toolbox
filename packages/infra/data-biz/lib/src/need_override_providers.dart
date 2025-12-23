import 'package:core/di.dart';
import 'package:core/object.dart';

import '../data_biz.dart';
import 'domain/data_source.dart';

part 'need_override_providers.g.dart';

@Riverpod(keepAlive: true)
List<Migratable<dynamic>> migrations(Ref ref) {
  return [];
}
