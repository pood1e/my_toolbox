import 'package:app_core/object.dart';

part 'name_editor_state.freezed.dart';

@freezed
abstract class NameEditData with _$NameEditData {
  const factory NameEditData({
    required Map<String, dynamic> config,
    String? data,
  }) = _NameEditData;
}

@freezed
abstract class NameReadData with _$NameReadData {
  const factory NameReadData({required bool isValid, String? data}) =
      _NameReadData;
}
