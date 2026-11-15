abstract class PlatformFileStorage {
  Future<String?> readString(String name);
  Future<void> writeString(String name, String content);
  Future<void> delete(String name);
  Future<bool> exists(String name);
}

PlatformFileStorage getPlatformFileStorage() =>
    throw UnsupportedError('Cannot create platform file storage');
