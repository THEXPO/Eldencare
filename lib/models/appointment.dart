class Appointment {
  const Appointment({
    required this.id,
    required this.doctorName,
    required this.speciality,
    required this.dateTime,
    required this.location,
    this.notes,
  });

  final String id;
  final String doctorName;
  final String speciality;
  final DateTime dateTime;
  final String location;
  final String? notes;

  bool get isUpcoming => dateTime.isAfter(DateTime.now());

  Appointment copyWith({
    String? doctorName,
    String? speciality,
    DateTime? dateTime,
    String? location,
    String? notes,
  }) {
    return Appointment(
      id: id,
      doctorName: doctorName ?? this.doctorName,
      speciality: speciality ?? this.speciality,
      dateTime: dateTime ?? this.dateTime,
      location: location ?? this.location,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'doctorName': doctorName,
    'speciality': speciality,
    'dateTime': dateTime.toIso8601String(),
    'location': location,
    'notes': notes,
  };

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
    id: json['id'] as String,
    doctorName: json['doctorName'] as String,
    speciality: json['speciality'] as String,
    dateTime: DateTime.parse(json['dateTime'] as String),
    location: json['location'] as String,
    notes: json['notes'] as String?,
  );
}
