import 'package:auth_biz/auth_biz.dart';

sealed class Scope {
  String get id;
}

class GlobalScope extends Scope {
  @override
  String get id => 'global';
}

class GuestScope extends Scope {
  @override
  String get id => 'guest';
}

class UserScope extends Scope {
  final UserIdentity _identity;

  UserScope({required UserIdentity identity}) : _identity = identity;

  @override
  String get id => _identity.hash;
}
