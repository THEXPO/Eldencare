import 'package:eldencare/app.dart';
import 'package:eldencare/models/care_snapshot.dart';
import 'package:eldencare/providers/care_provider.dart';
import 'package:eldencare/providers/role_provider.dart';
import 'package:eldencare/repositories/care_repository.dart';
import 'package:eldencare/services/seed_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class MemoryCareRepository implements CareRepository {
  MemoryCareRepository(this.snapshot);

  CareSnapshot snapshot;

  @override
  Future<CareSnapshot> load() async => snapshot;

  @override
  Future<void> save(CareSnapshot next) async {
    snapshot = next;
  }
}

void main() {
  testWidgets('role selector is shown on launch', (tester) async {
    final care = CareProvider(
      repository: MemoryCareRepository(SeedData.build()),
    );
    await care.load();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => RoleProvider()),
          ChangeNotifierProvider.value(value: care),
        ],
        child: const EldenCareApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('EldenCare'), findsWidgets);
    expect(find.text('Patient mode'), findsOneWidget);
    expect(find.text('Caretaker mode'), findsOneWidget);
  });
}
