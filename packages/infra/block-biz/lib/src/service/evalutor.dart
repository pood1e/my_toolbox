import '../domain/property.dart';

abstract class EvalutorContext {
  Future<Map<PropertyKey, Property>> getProperties(Set<PropertyKey> keys);

  Future<Property?> getProperty(PropertyKey key);

  Future<T> convertValue<T>(PropertyKey key, Property value);
}

abstract class Evalutor<C, T> {
  Future<T> eval(EvalutorContext ctx, C config);
}

sealed class EvalutionException implements Exception {}

class DependencyDirtyException extends EvalutionException {}

class DependencyErrorException extends EvalutionException {}
