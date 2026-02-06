import '../domain/property.dart';
import '../domain/stored_value.dart';

abstract class ComputeEngineContext {
  Future<Map<PropertyKey, Property>> getProperties(Set<PropertyKey> keys);

  Future<Property?> getProperty(PropertyKey key);

  Future<T> convertValue<T>(PropertyKey key, NormalStoredValue value);
}

sealed class ComputeException implements Exception {}

class DependencyDirtyException extends ComputeException {}

class DependencyErrorException extends ComputeException {}
