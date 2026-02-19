// event loop

import '../../meta/property_meta_service.dart';

abstract class ComputeWorker {
  Future<bool> work(
    PropertyId propertyId
  );
}
