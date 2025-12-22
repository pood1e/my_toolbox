sealed class SyncException implements Exception {}

class SyncConcurrentException extends SyncException {}

class SyncDelegateNotFoundException extends SyncException {}

class SyncUnavailableException extends SyncException {}


