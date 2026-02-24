import '../../relation/relation_service.dart';
import '../../value/value_service.dart';
import '../impl/compute_node.dart';

class RefSource extends Source<RelationData, dynamic> {
  final ValueService _valueService;

  RefSource({required ValueService valueService})
    : _valueService = valueService;

  @override
  String get computeId => 'ref_source';

  @override
  Future<dynamic> create(RelationData config) async {
    final val = await _valueService.getValue(config.dst);
    return val!.value;
  }
}
