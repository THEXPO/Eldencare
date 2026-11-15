import 'enums.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.fullName,
    required this.role,
    this.phone,
    this.avatarUrl,
    this.isDoctorApproved = false,
    this.workspaceId,
    this.assignedPatientIds = const [],
  });

  final String id;
  final String fullName;
  final AppRole role;
  final String? phone;
  final String? avatarUrl;
  final bool isDoctorApproved;
  final String? workspaceId;
  final List<String> assignedPatientIds;

  bool get isPatient => role == AppRole.patient;
  bool get isCaretaker => role == AppRole.caretaker;
  bool get isDoctor => role == AppRole.doctor;

  UserProfile copyWith({
    String? id,
    String? fullName,
    AppRole? role,
    String? phone,
    String? avatarUrl,
    bool? isDoctorApproved,
    String? workspaceId,
    List<String>? assignedPatientIds,
  }) {
    return UserProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isDoctorApproved: isDoctorApproved ?? this.isDoctorApproved,
      workspaceId: workspaceId ?? this.workspaceId,
      assignedPatientIds: assignedPatientIds ?? this.assignedPatientIds,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'full_name': fullName,
    'role': role.name,
    'phone': phone,
    'avatar_url': avatarUrl,
    'is_doctor_approved': isDoctorApproved,
    'workspace_id': workspaceId,
    'assigned_patient_ids': assignedPatientIds,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    AppRole parsedRole;
    final roleStr = json['role'] as String? ?? 'patient';
    switch (roleStr.toLowerCase()) {
      case 'caretaker':
        parsedRole = AppRole.caretaker;
        break;
      case 'doctor':
        parsedRole = AppRole.doctor;
        break;
      case 'patient':
      default:
        parsedRole = AppRole.patient;
        break;
    }

    return UserProfile(
      id: json['id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? 'EldenCare Member',
      role: parsedRole,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      isDoctorApproved: json['is_doctor_approved'] as bool? ?? false,
      workspaceId: json['workspace_id'] as String?,
      assignedPatientIds:
          (json['assigned_patient_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}
