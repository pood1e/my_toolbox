abstract class StringConverter<C> {
  C decode(String? config);

  String? encode(C config);
}

class SimpleStringConverter implements StringConverter<String> {
  @override
  String decode(String? config) => config!;

  @override
  String? encode(String config) => config;
}

class NoneStringConverter implements StringConverter<void> {
  @override
  void decode(String? config) {}

  @override
  String? encode(void config) => null;
}
