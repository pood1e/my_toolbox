import 'package:auth_biz/auth_biz.dart';

import '../domain/kv_store.dart';

abstract class KvService {
  KvStore openGlobalKv();

  KvStore openUserKv(UserIdentity userId);

  KvStore openGuestKv();
}
