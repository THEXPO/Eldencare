import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../models/care_relationship.dart';
import '../models/enums.dart';
import '../models/user_profile.dart';

enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  pendingOnboarding, // Caretaker without patients or doctor unapproved
}

class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    _init();
  }

  User? _user;
  UserProfile? _profile;
  List<CareRelationship> _relationships = [];
  bool _isLoading = true;
  String? _error;
  bool _isDemoMode = false;
  AuthStatus _status = AuthStatus.initial;

  User? get user => _user;
  UserProfile? get profile => _profile;
  List<CareRelationship> get relationships => _relationships;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isDemoMode => _isDemoMode;
  AuthStatus get status => _status;

  bool get isAuthenticated => _status == AuthStatus.authenticated;
  AppRole? get role => _profile?.role;

  SupabaseClient? get _supabase {
    if (SupabaseConfig.isConfigured) {
      try {
        return Supabase.instance.client;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    try {
      final client = _supabase;
      if (client != null) {
        // Listen to remote auth state changes
        client.auth.onAuthStateChange.listen((data) async {
          final session = data.session;
          if (session != null) {
            await _loadRemoteProfile(session.user);
          } else if (!_isDemoMode) {
            _clearSession();
          }
        });

        final currentSession = client.auth.currentSession;
        if (currentSession != null) {
          await _loadRemoteProfile(currentSession.user);
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      // Check saved local/demo session in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final savedUserJson = prefs.getString('eldencare_auth_profile');
      final isDemo = prefs.getBool('eldencare_auth_is_demo') ?? false;

      if (savedUserJson != null && savedUserJson.isNotEmpty) {
        _profile = UserProfile.fromJson(
          jsonDecode(savedUserJson) as Map<String, dynamic>,
        );
        _isDemoMode = isDemo;
        _evaluateStatus();
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e, st) {
      debugPrint('AuthProvider init error: $e\n$st');
      _status = AuthStatus.unauthenticated;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadRemoteProfile(User user) async {
    _user = user;
    try {
      final client = _supabase;
      if (client == null) return;

      final res = await client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (res != null) {
        _profile = UserProfile.fromJson(res);
      } else {
        // Fallback default profile if trigger hasn't finished
        final roleStr =
            user.userMetadata?['role'] as String? ?? AppRole.patient.name;
        final fullName =
            user.userMetadata?['full_name'] as String? ?? 'EldenCare Member';
        _profile = UserProfile(
          id: user.id,
          fullName: fullName,
          role: roleStr == 'caretaker'
              ? AppRole.caretaker
              : (roleStr == 'doctor' ? AppRole.doctor : AppRole.patient),
          isDoctorApproved: roleStr != 'doctor',
        );
      }

      // Fetch relationships for caretaker or doctor
      await _fetchRemoteRelationships(user.id);
      _evaluateStatus();
      await _persistSession();
    } catch (e, st) {
      debugPrint('Error loading remote profile: $e\n$st');
      _evaluateStatus();
    }
  }

  Future<void> _fetchRemoteRelationships(String userId) async {
    final client = _supabase;
    if (client == null || _profile == null) return;

    try {
      final rels = <CareRelationship>[];
      if (_profile!.isCaretaker) {
        final data = await client
            .from('care_team_members')
            .select('id, patient_id, relationship_role, status, permissions')
            .eq('user_id', userId);
        for (final item in (data as List<dynamic>)) {
          rels.add(
            CareRelationship.fromJson(
              Map<String, dynamic>.from(item as Map<dynamic, dynamic>),
            ),
          );
        }
      } else if (_profile!.isDoctor) {
        final data = await client
            .from('doctor_patient_assignments')
            .select('id, patient_id, status')
            .eq('doctor_user_id', userId);
        for (final item in (data as List<dynamic>)) {
          rels.add(
            CareRelationship(
              id: item['id'] as String,
              patientId: item['patient_id'] as String,
              patientName: 'Assigned Patient',
              relationshipRole: 'attending_physician',
              status: item['status'] as String? ?? 'approved',
            ),
          );
        }
      }
      _relationships = rels;
    } catch (e) {
      debugPrint('Error fetching care relationships: $e');
    }
  }

  void _evaluateStatus() {
    if (_profile == null) {
      _status = AuthStatus.unauthenticated;
      return;
    }

    if (_profile!.isPatient) {
      _status = AuthStatus.authenticated;
    } else if (_profile!.isCaretaker) {
      if (_relationships.any((r) => r.isActive)) {
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.pendingOnboarding;
      }
    } else if (_profile!.isDoctor) {
      if (_profile!.isDoctorApproved) {
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.pendingOnboarding;
      }
    } else {
      _status = AuthStatus.authenticated;
    }
  }

  // ---------------------------------------------------------------------------
  // Sign In
  // ---------------------------------------------------------------------------
  Future<bool> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final cleanEmail = email.trim().toLowerCase();
    final client = _supabase;

    try {
      if (client != null) {
        final res = await client.auth.signInWithPassword(
          email: cleanEmail,
          password: password,
        );
        if (res.user != null) {
          await _loadRemoteProfile(res.user!);
          _isDemoMode = false;
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }

      // Offline / Local Demo Fallback Authentication
      if (cleanEmail.contains('patient') || cleanEmail == 'eleanor@eldencare.org') {
        _profile = const UserProfile(
          id: 'demo-patient-001',
          fullName: 'Eleanor Vance',
          role: AppRole.patient,
          workspaceId: 'p1',
        );
      } else if (cleanEmail.contains('caretaker') || cleanEmail == 'priya@eldencare.org') {
        _profile = const UserProfile(
          id: 'demo-caretaker-001',
          fullName: 'Priya Hart',
          role: AppRole.caretaker,
        );
        _relationships = [
          const CareRelationship(
            id: 'rel-1',
            patientId: 'p1',
            patientName: 'Eleanor Vance',
            relationshipRole: 'Primary Caregiver (Daughter)',
            status: 'active',
          ),
        ];
      } else if (cleanEmail.contains('doctor') || cleanEmail == 'doctor@eldencare.org') {
        _profile = const UserProfile(
          id: 'demo-doctor-001',
          fullName: 'Dr. Sarah Nguyen, MD',
          role: AppRole.doctor,
          isDoctorApproved: true,
        );
        _relationships = [
          const CareRelationship(
            id: 'doc-rel-1',
            patientId: 'p1',
            patientName: 'Eleanor Vance',
            relationshipRole: 'Lead Geriatrician',
            status: 'approved',
          ),
          const CareRelationship(
            id: 'doc-rel-2',
            patientId: 'p2',
            patientName: 'Arthur Vance',
            relationshipRole: 'Cardiologist',
            status: 'approved',
          ),
        ];
      } else {
        // Custom registered account
        final prefs = await SharedPreferences.getInstance();
        final stored = prefs.getString('account_$cleanEmail');
        if (stored != null) {
          final data = jsonDecode(stored) as Map<String, dynamic>;
          if (data['password'] == password) {
            _profile = UserProfile.fromJson(data['profile'] as Map<String, dynamic>);
            _relationships = (data['relationships'] as List<dynamic>? ?? [])
                .map((e) => CareRelationship.fromJson(e as Map<String, dynamic>))
                .toList();
          } else {
            _error = 'Invalid email or password.';
            _isLoading = false;
            notifyListeners();
            return false;
          }
        } else {
          _error = 'Invalid credentials or user not found.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      _isDemoMode = true;
      _evaluateStatus();
      await _persistSession();
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Sign in failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Sign Up
  // ---------------------------------------------------------------------------
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    required AppRole role,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final cleanEmail = email.trim().toLowerCase();
    final client = _supabase;

    try {
      if (client != null) {
        final res = await client.auth.signUp(
          email: cleanEmail,
          password: password,
          data: {'full_name': fullName.trim(), 'role': role.name},
        );

        if (res.user != null) {
          _user = res.user;
          _profile = UserProfile(
            id: res.user!.id,
            fullName: fullName.trim(),
            role: role,
            isDoctorApproved: role != AppRole.doctor,
            workspaceId: role == AppRole.patient ? 'pat_${res.user!.id.substring(0, 8)}' : null,
          );
          _evaluateStatus();
          await _persistSession();
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }

      // Local / Offline demo signup
      final newId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      _profile = UserProfile(
        id: newId,
        fullName: fullName.trim(),
        role: role,
        isDoctorApproved: role != AppRole.doctor, // Doctors require approval
        workspaceId: role == AppRole.patient ? 'pat_$newId' : null,
      );
      _relationships = [];
      _isDemoMode = true;

      // Persist registered credentials locally for offline restart
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'account_$cleanEmail',
        jsonEncode({
          'password': password,
          'profile': _profile!.toJson(),
          'relationships': _relationships.map((r) => r.toJson()).toList(),
        }),
      );

      _evaluateStatus();
      await _persistSession();
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Registration failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Password Recovery
  // ---------------------------------------------------------------------------
  Future<bool> sendPasswordResetEmail(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final cleanEmail = email.trim().toLowerCase();
    final client = _supabase;

    try {
      if (client != null) {
        await client.auth.resetPasswordForEmail(cleanEmail);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Password reset failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Caretaker / Doctor Invitation Code Redemption
  // ---------------------------------------------------------------------------
  Future<bool> redeemInvitationCode(String code) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final cleanCode = code.trim().toUpperCase();
    final client = _supabase;

    try {
      if (client != null) {
        final res = await client.rpc(
          'redeem_invitation',
          params: {'p_code': cleanCode},
        );
        final map = Map<String, dynamic>.from(res as Map);
        if (map['success'] == true) {
          if (_user != null) {
            await _fetchRemoteRelationships(_user!.id);
          }
          _evaluateStatus();
          await _persistSession();
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          _error = map['message'] as String? ?? 'Invalid or expired invitation code.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      // Offline Demo Code Redemption Validation
      if (cleanCode == 'ELDEN-CARE-789' || cleanCode == 'CARE-789') {
        _relationships.add(
          const CareRelationship(
            id: 'rel-demo-1',
            patientId: 'p1',
            patientName: 'Eleanor Vance',
            relationshipRole: 'Family Caregiver',
            status: 'active',
          ),
        );
      } else if (cleanCode == 'ELDEN-CARE-456' || cleanCode == 'CARE-456') {
        _relationships.add(
          const CareRelationship(
            id: 'rel-demo-2',
            patientId: 'p2',
            patientName: 'Arthur Vance',
            relationshipRole: 'Assigned Caregiver',
            status: 'active',
          ),
        );
      } else if (cleanCode == 'DOCTOR-CLINIC-456' || cleanCode == 'DOC-456') {
        if (_profile != null) {
          _profile = _profile!.copyWith(isDoctorApproved: true);
        }
        _relationships.add(
          const CareRelationship(
            id: 'rel-doc-1',
            patientId: 'p1',
            patientName: 'Eleanor Vance',
            relationshipRole: 'Assigned Geriatrician',
            status: 'approved',
          ),
        );
      } else {
        _error = 'Invalid invitation code. For demo, try: ELDEN-CARE-789';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _evaluateStatus();
      await _persistSession();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to redeem invitation code: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Doctor Verification / Approval (Demo Process)
  // ---------------------------------------------------------------------------
  Future<void> approveDoctorDemo() async {
    if (_profile == null || !_profile!.isDoctor) return;
    _profile = _profile!.copyWith(isDoctorApproved: true);
    if (_relationships.isEmpty) {
      _relationships = [
        const CareRelationship(
          id: 'rel-doc-demo',
          patientId: 'p1',
          patientName: 'Eleanor Vance',
          relationshipRole: 'Assending Doctor',
          status: 'approved',
        ),
      ];
    }
    _evaluateStatus();
    await _persistSession();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // One-Click Hackathon Demo Mode Switcher
  // ---------------------------------------------------------------------------
  Future<void> enterDemoMode(AppRole demoRole) async {
    _isLoading = true;
    _isDemoMode = true;
    notifyListeners();

    switch (demoRole) {
      case AppRole.patient:
        _profile = const UserProfile(
          id: 'demo-patient-001',
          fullName: 'Eleanor Vance',
          role: AppRole.patient,
          workspaceId: 'p1',
        );
        _relationships = [];
        break;
      case AppRole.caretaker:
        _profile = const UserProfile(
          id: 'demo-caretaker-001',
          fullName: 'Priya Hart',
          role: AppRole.caretaker,
        );
        _relationships = [
          const CareRelationship(
            id: 'rel-1',
            patientId: 'p1',
            patientName: 'Eleanor Vance',
            relationshipRole: 'Primary Caregiver (Daughter)',
            status: 'active',
          ),
        ];
        break;
      case AppRole.doctor:
        _profile = const UserProfile(
          id: 'demo-doctor-001',
          fullName: 'Dr. Sarah Nguyen, MD',
          role: AppRole.doctor,
          isDoctorApproved: true,
        );
        _relationships = [
          const CareRelationship(
            id: 'doc-rel-1',
            patientId: 'p1',
            patientName: 'Eleanor Vance',
            relationshipRole: 'Lead Geriatrician',
            status: 'approved',
          ),
          const CareRelationship(
            id: 'doc-rel-2',
            patientId: 'p2',
            patientName: 'Arthur Vance',
            relationshipRole: 'Cardiologist',
            status: 'approved',
          ),
          const CareRelationship(
            id: 'doc-rel-3',
            patientId: 'p3',
            patientName: 'Kamala Sharma',
            relationshipRole: 'Primary Physician',
            status: 'approved',
          ),
        ];
        break;
    }

    _evaluateStatus();
    await _persistSession();
    _isLoading = false;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Sign Out & Session Teardown
  // ---------------------------------------------------------------------------
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      final client = _supabase;
      if (client != null) {
        await client.auth.signOut();
      }
    } catch (_) {}

    await _clearSession();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _persistSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (_profile != null) {
      await prefs.setString(
        'eldencare_auth_profile',
        jsonEncode(_profile!.toJson()),
      );
      await prefs.setBool('eldencare_auth_is_demo', _isDemoMode);
    }
  }

  Future<void> _clearSession() async {
    _user = null;
    _profile = null;
    _relationships = [];
    _isDemoMode = false;
    _status = AuthStatus.unauthenticated;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('eldencare_auth_profile');
    await prefs.remove('eldencare_auth_is_demo');
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
