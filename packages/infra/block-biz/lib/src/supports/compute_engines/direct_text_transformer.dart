import '../../domain/compute_engine.dart';

class DirectTextTransformer implements Transformer<String, void, String> {
  @override
  void fromDb(Map<String, dynamic> value) {}

  @override
  String get id => 'direct_text';

  @override
  String get sTypeId => 'text';

  @override
  String get tTypeId => 'text';

  @override
  Map<String, dynamic> toDb(void value) => {};

  @override
  Future<String> transform(String source, void config) async => source;

  @override
  String? validate(void value) => null;
}
