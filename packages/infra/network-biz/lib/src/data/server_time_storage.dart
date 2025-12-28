abstract class ServerTimeStorage {
  Future<int> getAnchor();

  Future<void> saveAnchor(int anchor);

  Future<String?> getBootId();

  Future<void> saveBootId(String bootId);
}
