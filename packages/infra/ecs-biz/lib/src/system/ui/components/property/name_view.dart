import 'package:app_core/di.dart';

import '../../../config/config_service.dart';
import '../../../meta/property_meta_service.dart';

part 'name_view.g.dart';

@riverpod
Stream<String?> watchNodeNameVal(Ref ref, String nodeId) async* {
  final service = await ref.watch(configServiceProvider.future);
  yield* service
      .watch(PropertyId(nodeId: nodeId, metaId: '_name'))
      .map((result) => result?.text);
}
