abstract class InstallIdStorage {
  Future<String?> getInstallId();

  Future<void> saveInstallId(String uid);
}