import 'package:app_core/di.dart';

import '../domain/connection_availability.dart';

part 'connection_availabilty_notifier.g.dart';

@Riverpod(keepAlive: true)
class ConnectionAvailabiltyNotifier extends _$ConnectionAvailabiltyNotifier {
  @override
  ConnectionAvailability build() {
    return ConnectionAvailability.verifying;
  }

  void save(ConnectionAvailability availability) {
    if (availability != state) {
      state = availability;
    }
  }
}
