/// Model representing an audit log entry.
class AuditLogEntry {
  final int id;
  final DateTime timestamp;
  final int userId;
  final String action;
  final String status;
  final String? details;

  AuditLogEntry({
    required this.id,
    required this.timestamp,
    required this.userId,
    required this.action,
    required this.status,
    this.details,
  });

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) {
    return AuditLogEntry(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      timestamp: DateTime.parse(json['timestamp']),
      userId: json['user_id'] is int
          ? json['user_id']
          : int.tryParse(json['user_id'].toString()) ?? 0,
      action: json['action'] ?? '',
      status: json['status'] ?? '',
      details: json['details'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'user_id': userId,
        'action': action,
        'status': status,
        'details': details,
      };
}