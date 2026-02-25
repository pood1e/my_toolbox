import 'package:app_core/di.dart';

import '../../meta/property_meta_service.dart';
import '../../value/value_service.dart';
import '../impl/compute_node.dart';

part 'ref_source.g.dart';

class RefSource extends Source<PropertyId, dynamic> {
  final ValueService _valueService;

  RefSource({required ValueService valueService})
    : _valueService = valueService;

  @override
  String get computeId => 'ref_source';

  @override
  Future<dynamic> create(PropertyId self, PropertyId propertyId) async {
    final val = await _valueService.getValue(propertyId);
    return val!.value;
  }
}

@riverpod
Future<RefSource> refSource(Ref ref) async {
  final valueService = await ref.watch(valueServiceProvider.future);
  return RefSource(valueService: valueService);
}
