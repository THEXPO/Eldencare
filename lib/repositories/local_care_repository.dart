import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/care_snapshot.dart';
import '../services/seed_data.dart';
import 'care_repository.dart';
import 'storage/file_storage.dart';

/// Workspace-isolated local repository.
///
/// Ensures patient data is strictly namespaced by workspaceId
/// so multiple accounts never leak cached health data to one another.
/// Uses platform-safe storage (file system on native platforms,
/// SharedPreferences / LocalStorage on Web).
class LocalCareRepository implements CareRepository {
  LocalCareRepository({this.workspaceId = 'default_demo'});

  final String workspaceId;

  String get fileName => 'eldencare_snapshot_$workspaceId.json';

  @override
  Future<CareSnapshot> load() async {
    // 1. Attempt reading from platform file storage (mobile/desktop)
    final fileExists = await platformFileStorage.exists(fileName);
    if (fileExists) {
      try {
        final raw = await platformFileStorage.readString(fileName);
        if (raw != null && raw.isNotEmpty) {
          return CareSnapshot.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        }
      } catch (e, st) {
        debugPrint(
          'File load failed, falling back to SharedPreferences: $e\n$st',
        );
      }
    } else if (workspaceId == 'default_demo') {
      // Check legacy root file if default demo
      final legacyExists =
          await platformFileStorage.exists('eldencare_snapshot.json');
      if (legacyExists) {
        final raw =
            await platformFileStorage.readString('eldencare_snapshot.json');
        if (raw != null && raw.isNotEmpty) {
          return CareSnapshot.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        }
      }
    }

    // 2. Read from SharedPreferences / LocalStorage (universal & web)
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(fileName);
    if (raw == null || raw.isEmpty) {
      if (workspaceId == 'default_demo') {
        final legacy = prefs.getString('eldencare_snapshot.json');
        if (legacy != null && legacy.isNotEmpty) {
          return CareSnapshot.fromJson(
            jsonDecode(legacy) as Map<String, dynamic>,
          );
        }
      }
      final seeded = SeedData.build();
      await save(seeded);
      return seeded;
    }

    return CareSnapshot.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> save(CareSnapshot snapshot) async {
    final serialized = jsonEncode(snapshot.toJson());

    // 1. Write to platform file storage if available
    try {
      await platformFileStorage.writeString(fileName, serialized);
    } catch (e, st) {
      debugPrint('File save failed, saving to SharedPreferences: $e\n$st');
    }

    // 2. Write to SharedPreferences / LocalStorage
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(fileName, serialized);
  }

  /// Clears in-memory & cached data for a specific workspace upon logout
  Future<void> clearWorkspace() async {
    try {
      await platformFileStorage.delete(fileName);
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(fileName);
  }
}
