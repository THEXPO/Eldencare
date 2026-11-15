import 'dart:io';
import 'package:path_provider/path_provider.dart';

import 'file_storage_stub.dart';
export 'file_storage_stub.dart' show PlatformFileStorage;

class IoFileStorage implements PlatformFileStorage {
  Future<File?> _file(String name) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      return File('${dir.path}/$name');
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> readString(String name) async {
    try {
      final file = await _file(name);
      if (file != null && await file.exists()) {
        return await file.readAsString();
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<void> writeString(String name, String content) async {
    try {
      final file = await _file(name);
      if (file != null) {
        await file.writeAsString(content);
      }
    } catch (_) {}
  }

  @override
  Future<void> delete(String name) async {
    try {
      final file = await _file(name);
      if (file != null && await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  @override
  Future<bool> exists(String name) async {
    try {
      final file = await _file(name);
      return file != null && await file.exists();
    } catch (_) {
      return false;
    }
  }
}

PlatformFileStorage getPlatformFileStorage() => IoFileStorage();
