sealed class SyncException implements Exception {}

class SyncConcurrentException extends SyncException {}

class SyncDelegateNotFoundException extends SyncException {}

class SyncDisallowException extends SyncException {}

class SyncFailedException extends SyncException {
  final String message;

  SyncFailedException({required this.message});
}

class SyncUnavailableException extends SyncException {}