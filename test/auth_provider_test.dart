import 'package:eldencare/models/enums.dart';
import 'package:eldencare/models/user_profile.dart';
import 'package:eldencare/providers/auth_provider.dart';
import 'package:eldencare/repositories/local_care_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Phase 2: AuthProvider & Access Control Tests', () {
    test('Initial unauthenticated state', () async {
      final auth = AuthProvider();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(auth.isAuthenticated, isFalse);
      expect(auth.status, equals(AuthStatus.unauthenticated));
      expect(auth.profile, isNull);
    });

    test('Patient can register and automatically get authenticated workspace', () async {
      final auth = AuthProvider();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final success = await auth.signUp(
        email: 'eleanor@test.org',
        password: 'password123',
        fullName: 'Eleanor Vance',
        role: AppRole.patient,
      );

      expect(success, isTrue);
      expect(auth.isAuthenticated, isTrue);
      expect(auth.status, equals(AuthStatus.authenticated));
      expect(auth.role, equals(AppRole.patient));
      expect(auth.profile?.workspaceId, isNotNull);
    });

    test('Caretaker registers into pendingOnboarding until redeeming invitation code', () async {
      final auth = AuthProvider();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final success = await auth.signUp(
        email: 'priya@test.org',
        password: 'password123',
        fullName: 'Priya Hart',
        role: AppRole.caretaker,
      );

      expect(success, isTrue);
      // Unassigned caretaker CANNOT access patient records yet
      expect(auth.isAuthenticated, isFalse);
      expect(auth.status, equals(AuthStatus.pendingOnboarding));
      expect(auth.relationships, isEmpty);

      // Caretaker enters invitation code
      final redeemed = await auth.redeemInvitationCode('ELDEN-CARE-789');
      expect(redeemed, isTrue);

      // Now assigned and authorized!
      expect(auth.isAuthenticated, isTrue);
      expect(auth.status, equals(AuthStatus.authenticated));
      expect(auth.relationships.length, equals(1));
      expect(auth.relationships.first.patientName, equals('Eleanor Vance'));
    });

    test('Doctor registers into pendingOnboarding until credentials approval', () async {
      final auth = AuthProvider();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final success = await auth.signUp(
        email: 'doctor@test.org',
        password: 'password123',
        fullName: 'Dr. Sarah Nguyen',
        role: AppRole.doctor,
      );

      expect(success, isTrue);
      // Unapproved doctor CANNOT access doctor privileges or patient care plans
      expect(auth.isAuthenticated, isFalse);
      expect(auth.status, equals(AuthStatus.pendingOnboarding));
      expect(auth.profile?.isDoctorApproved, isFalse);

      // Doctor is approved
      await auth.approveDoctorDemo();
      expect(auth.isAuthenticated, isTrue);
      expect(auth.status, equals(AuthStatus.authenticated));
      expect(auth.profile?.isDoctorApproved, isTrue);
    });

    test('Invalid invitation code is rejected with error message', () async {
      final auth = AuthProvider();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await auth.signUp(
        email: 'caretaker@test.org',
        password: 'password123',
        fullName: 'Test Caretaker',
        role: AppRole.caretaker,
      );

      final redeemed = await auth.redeemInvitationCode('INVALID-CODE-999');
      expect(redeemed, isFalse);
      expect(auth.error, contains('Invalid invitation code'));
      expect(auth.status, equals(AuthStatus.pendingOnboarding));
    });

    test('Password reset request succeeds', () async {
      final auth = AuthProvider();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final success = await auth.sendPasswordResetEmail('eleanor@test.org');
      expect(success, isTrue);
      expect(auth.error, isNull);
    });

    test('Sign out clears session and relationships', () async {
      final auth = AuthProvider();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await auth.enterDemoMode(AppRole.caretaker);
      expect(auth.isAuthenticated, isTrue);
      expect(auth.relationships.isNotEmpty, isTrue);

      await auth.signOut();
      expect(auth.isAuthenticated, isFalse);
      expect(auth.status, equals(AuthStatus.unauthenticated));
      expect(auth.profile, isNull);
      expect(auth.relationships, isEmpty);
    });

    test('LocalCareRepository isolates workspaces by ID', () {
      final repoA = LocalCareRepository(workspaceId: 'workspace_patient_1');
      final repoB = LocalCareRepository(workspaceId: 'workspace_patient_2');

      expect(repoA.fileName, equals('eldencare_snapshot_workspace_patient_1.json'));
      expect(repoB.fileName, equals('eldencare_snapshot_workspace_patient_2.json'));
      expect(repoA.fileName, isNot(equals(repoB.fileName)));
    });
  });
}
