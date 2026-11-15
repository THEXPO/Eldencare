import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/care_snapshot.dart';
import '../services/seed_data.dart';
import 'care_repository.dart';

/// Workspace-isolated local repository.
///
/// Ensures patient data is strictly namespaced by workspaceId
/// so multiple accounts never leak cached health data to one another.
class LocalCareRepository implements CareRepository {
  LocalCareRepository({this.workspaceId = 'default_demo'});

  final String workspaceId;

  String get fileName => 'eldencare_snapshot_$workspaceId.json';

  Future<File?> _file(String name) async {
    if (kIsWeb) return null;
    try {
      final dir = await getApplicationDocumentsDirectory();
      return File('${dir.path}/$name');
    } catch (_) {
      return null;
    }
  }

  @override
  Future<CareSnapshot> load() async {
    final file = await _file(fileName);
    if (file != null) {
      try {
        if (!await file.exists()) {
          // Check for legacy root snapshot file if default_demo
          if (workspaceId == 'default_demo') {
            final legacy = await _file('eldencare_snapshot.json');
            if (legacy != null && await legacy.exists()) {
              final raw = await legacy.readAsString();
              return CareSnapshot.fromJson(
                jsonDecode(raw) as Map<String, dynamic>,
              );
            }
          }
          final seeded = SeedData.build();
          await save(seeded);
          return seeded;
        }
        final raw = await file.readAsString();
        return CareSnapshot.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (e, st) {
        debugPrint(
          'File load failed, falling back to SharedPreferences: $e\n$st',
        );
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(fileName);
    if (raw == null || raw.isEmpty) {
      // Check legacy prefs if default_demo
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
    final file = await _file(fileName);
    if (file != null) {
      try {
        await file.writeAsString(jsonEncode(snapshot.toJson()));
      } catch (e, st) {
        debugPrint('File save failed, saving to SharedPreferences: $e\n$st');
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(fileName, jsonEncode(snapshot.toJson()));
  }

  /// Clears in-memory & cached data for a specific workspace upon logout
  Future<void> clearWorkspace() async {
    final file = await _file(fileName);
    if (file != null && await file.exists()) {
      try {
        await file.delete();
      } catch (_) {}
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(fileName);
  }
}
