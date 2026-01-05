import 'package:data_api/data_api.dart';

import '../domain/sync_object.dart';

abstract class LwwObject implements SyncObject, IdObject {
  int get updatedAt;
}

abstract class LwwAck implements SyncObject, IdObject {}

class LwwAckUpdate {
  final LwwAck ack;
  final int updatedAt;

  LwwAckUpdate({required this.ack, required this.updatedAt});
}
