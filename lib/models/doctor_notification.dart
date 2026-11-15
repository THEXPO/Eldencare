class DoctorNotification {
  const DoctorNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.category,
    this.patientId,
    this.patientName,
  });

  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final String
  category; // 'carePlan', 'discrepancy', 'healthReading', 'consultation'
  final String? patientId;
  final String? patientName;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'message': message,
    'timestamp': timestamp.toIso8601String(),
    'category': category,
    'patientId': patientId,
    'patientName': patientName,
  };

  factory DoctorNotification.fromJson(Map<String, dynamic> json) =>
      DoctorNotification(
        id: json['id'] as String,
        title: json['title'] as String,
        message: json['message'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        category: json['category'] as String,
        patientId: json['patientId'] as String?,
        patientName: json['patientName'] as String?,
      );
}
