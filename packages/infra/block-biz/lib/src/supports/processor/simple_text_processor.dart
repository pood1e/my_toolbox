import 'package:app_core/object.dart';

import '../../domain/compute_engine.dart';

part 'simple_text_processor.freezed.dart';
part 'simple_text_processor.g.dart';

@freezed
abstract class SimpleText with _$SimpleText {
  const factory SimpleText({required String data}) = _SimpleText;

  factory SimpleText.fromJson(Map<String, dynamic> json) =>
      _$SimpleTextFromJson(json);
}

class SimpleTextProcessor implements Processor<SimpleText, String> {
  @override
  SimpleText fromDb(Map<String, dynamic> value) => SimpleText.fromJson(value);

  @override
  String get id => 'simple_text';

  @override
  Future<String> process(SimpleText config) async => config.data;

  @override
  Map<String, dynamic> toDb(SimpleText value) => value.toJson();

  @override
  String get typeId => 'text';

  @override
  String? validate(SimpleText value) => null;
}
