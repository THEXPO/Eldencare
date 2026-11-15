import 'package:eldencare/repositories/local_care_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalCareRepository', () {
    test('loads seed data when storage is empty', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = LocalCareRepository(fileName: 'test_snapshot_empty.json');
      final snapshot = await repo.load();

      expect(snapshot.patient.fullName, isNotEmpty);
      expect(snapshot.medications, isNotEmpty);
    });

    test('loads and saves updated snapshot', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = LocalCareRepository(fileName: 'test_snapshot_save.json');
      final initial = await repo.load();

      final updated = initial.copyWith(
        patient: initial.patient.copyWith(fullName: 'Jane Doe'),
      );

      await repo.save(updated);
      final reloaded = await repo.load();
      expect(reloaded.patient.fullName, 'Jane Doe');
    });
  });
}
