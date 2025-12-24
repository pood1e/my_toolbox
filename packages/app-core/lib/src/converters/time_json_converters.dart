import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:intl/intl.dart';

class DateJsonConverter implements JsonConverter<DateTime, String> {
  const DateJsonConverter();

  @override
  DateTime fromJson(String json) {
    return DateTime.parse(json);
  }

  @override
  String toJson(DateTime object) {
    return DateFormat('yyyy-MM-dd').format(object);
  }
}

class DateTimeConverter implements JsonConverter<DateTime, String> {
  const DateTimeConverter();

  @override
  DateTime fromJson(String str) {
    return DateTime.parse(str);
  }

  @override
  String toJson(DateTime object) {
    return object.toUtc().toIso8601String();
  }
}
