import '../models/care_snapshot.dart';

/// Data access for the active patient's care record.
/// Phase 1 uses local JSON. Later this can be backed by a REST API / Supabase.
abstract class CareRepository {
  Future<CareSnapshot> load();

  Future<void> save(CareSnapshot snapshot);
}
