import 'enums.dart';

class BloodPressureReading {
  const BloodPressureReading({
    required this.id,
    required this.systolic,
    required this.diastolic,
    required this.recordedAt,
    required this.recordedBy,
    this.notes,
  });

  final String id;
  final int systolic;
  final int diastolic;
  final DateTime recordedAt;
  final String recordedBy;
  final String? notes;

  Map<String, dynamic> toJson() => {
    'id': id,
    'systolic': systolic,
    'diastolic': diastolic,
    'recordedAt': recordedAt.toIso8601String(),
    'recordedBy': recordedBy,
    'notes': notes,
  };

  factory BloodPressureReading.fromJson(Map<String, dynamic> json) =>
      BloodPressureReading(
        id: json['id'] as String,
        systolic: json['systolic'] as int,
        diastolic: json['diastolic'] as int,
        recordedAt: DateTime.parse(json['recordedAt'] as String),
        recordedBy: json['recordedBy'] as String,
        notes: json['notes'] as String?,
      );
}

class GlucoseReading {
  const GlucoseReading({
    required this.id,
    required this.value,
    required this.unit,
    required this.recordedAt,
    required this.recordedBy,
    this.notes,
  });

  final String id;
  final double value;
  final GlucoseUnit unit;
  final DateTime recordedAt;
  final String recordedBy;
  final String? notes;

  Map<String, dynamic> toJson() => {
    'id': id,
    'value': value,
    'unit': unit.name,
    'recordedAt': recordedAt.toIso8601String(),
    'recordedBy': recordedBy,
    'notes': notes,
  };

  factory GlucoseReading.fromJson(Map<String, dynamic> json) => GlucoseReading(
    id: json['id'] as String,
    value: (json['value'] as num).toDouble(),
    unit: GlucoseUnit.values.byName(json['unit'] as String),
    recordedAt: DateTime.parse(json['recordedAt'] as String),
    recordedBy: json['recordedBy'] as String,
    notes: json['notes'] as String?,
  );
}
