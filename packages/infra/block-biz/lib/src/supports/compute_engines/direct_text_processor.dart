import 'package:app_core/object.dart';

import '../../domain/compute_engine.dart';

part 'direct_text_processor.freezed.dart';
part 'direct_text_processor.g.dart';

@freezed
abstract class DirectText with _$DirectText {
  const factory DirectText({required String data}) = _DirectText;

  factory DirectText.fromJson(Map<String, dynamic> json) =>
      _$DirectTextFromJson(json);
}

class DirectTextProcessor implements Processor<DirectText, String> {
  @override
  DirectText fromDb(Map<String, dynamic> value) => DirectText.fromJson(value);

  @override
  String get id => 'direct_text';

  @override
  Future<String> process(DirectText config) async => config.data;

  @override
  Map<String, dynamic> toDb(DirectText value) => value.toJson();

  @override
  String get typeId => 'text';

  @override
  String? validate(DirectText value) {
    if (value.data.isEmpty) {
      return 'text should not be empty';
    }
    return null;
  }
}
