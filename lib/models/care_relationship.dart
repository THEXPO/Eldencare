class CareRelationship {
  const CareRelationship({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.relationshipRole,
    required this.status,
    this.permissions = const {},
  });

  final String id;
  final String patientId;
  final String patientName;
  final String relationshipRole;
  final String status;
  final Map<String, dynamic> permissions;

  bool get isActive => status == 'active' || status == 'approved';

  Map<String, dynamic> toJson() => {
    'id': id,
    'patient_id': patientId,
    'patient_name': patientName,
    'relationship_role': relationshipRole,
    'status': status,
    'permissions': permissions,
  };

  factory CareRelationship.fromJson(Map<String, dynamic> json) {
    return CareRelationship(
      id: json['id'] as String? ?? '',
      patientId: json['patient_id'] as String? ?? '',
      patientName: json['patient_name'] as String? ?? 'Assigned Patient',
      relationshipRole: json['relationship_role'] as String? ?? 'primary',
      status: json['status'] as String? ?? 'active',
      permissions: json['permissions'] as Map<String, dynamic>? ?? const {},
    );
  }
}
