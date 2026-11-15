class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.notificationType,
    required this.createdAt,
    this.relatedEntityType,
    this.relatedEntityId,
    this.readAt,
  });

  final String id;
  final String title;
  final String body;
  final String notificationType;
  final DateTime createdAt;
  final String? relatedEntityType;
  final String? relatedEntityId;
  final DateTime? readAt;

  bool get isRead => readAt != null;

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    String? notificationType,
    DateTime? createdAt,
    String? relatedEntityType,
    String? relatedEntityId,
    DateTime? readAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      notificationType: notificationType ?? this.notificationType,
      createdAt: createdAt ?? this.createdAt,
      relatedEntityType: relatedEntityType ?? this.relatedEntityType,
      relatedEntityId: relatedEntityId ?? this.relatedEntityId,
      readAt: readAt ?? this.readAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'notification_type': notificationType,
    'created_at': createdAt.toIso8601String(),
    'related_entity_type': relatedEntityType,
    'related_entity_id': relatedEntityId,
    'read_at': readAt?.toIso8601String(),
  };

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Notification',
      body: json['body'] as String? ?? '',
      notificationType: json['notification_type'] as String? ?? 'general',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      relatedEntityType: json['related_entity_type'] as String?,
      relatedEntityId: json['related_entity_id'] as String?,
      readAt: json['read_at'] != null
          ? DateTime.tryParse(json['read_at'].toString())
          : null,
    );
  }
}
