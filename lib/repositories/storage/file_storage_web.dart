import 'file_storage_stub.dart';
export 'file_storage_stub.dart' show PlatformFileStorage;

class WebFileStorage implements PlatformFileStorage {
  @override
  Future<String?> readString(String name) async => null;

  @override
  Future<void> writeString(String name, String content) async {}

  @override
  Future<void> delete(String name) async {}

  @override
  Future<bool> exists(String name) async => false;
}

PlatformFileStorage getPlatformFileStorage() => WebFileStorage();
