export 'package:freezed_annotation/freezed_annotation.dart';
export 'package:json_annotation/json_annotation.dart';

export 'src/converters/time_json_converters.dart';
export 'src/exceptions/not_override_error.dart';
export 'src/result/result.dart';

typedef FromJson<T> = T Function(Map<String, dynamic>);
typedef ToJson<T> = Map<String, dynamic> Function(T);
