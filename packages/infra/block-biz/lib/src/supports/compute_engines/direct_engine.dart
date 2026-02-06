import '../../domain/type_descriptor.dart';

class DirectEngine<T> implements ComputeEngine<T, T> {
  @override
  Future<T> compute(T config) async => config;
}
