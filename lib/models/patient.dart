class Patient {
  const Patient({
    required this.id,
    required this.fullName,
    required this.preferredName,
    required this.dateOfBirth,
    required this.conditions,
    required this.caretakerName,
    required this.caretakerRelation,
    this.notes,
  });

  final String id;
  final String fullName;
  final String preferredName;
  final DateTime dateOfBirth;
  final List<String> conditions;
  final String caretakerName;
  final String caretakerRelation;
  final String? notes;

  int get age {
    final now = DateTime.now();
    var years = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      years--;
    }
    return years;
  }

  Patient copyWith({
    String? fullName,
    String? preferredName,
    DateTime? dateOfBirth,
    List<String>? conditions,
    String? caretakerName,
    String? caretakerRelation,
    String? notes,
  }) {
    return Patient(
      id: id,
      fullName: fullName ?? this.fullName,
      preferredName: preferredName ?? this.preferredName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      conditions: conditions ?? this.conditions,
      caretakerName: caretakerName ?? this.caretakerName,
      caretakerRelation: caretakerRelation ?? this.caretakerRelation,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'preferredName': preferredName,
    'dateOfBirth': dateOfBirth.toIso8601String(),
    'conditions': conditions,
    'caretakerName': caretakerName,
    'caretakerRelation': caretakerRelation,
    'notes': notes,
  };

  factory Patient.fromJson(Map<String, dynamic> json) => Patient(
    id: json['id'] as String,
    fullName: json['fullName'] as String,
    preferredName: json['preferredName'] as String,
    dateOfBirth: DateTime.parse(json['dateOfBirth'] as String),
    conditions: (json['conditions'] as List<dynamic>).cast<String>(),
    caretakerName: json['caretakerName'] as String,
    caretakerRelation: json['caretakerRelation'] as String,
    notes: json['notes'] as String?,
  );
}
