/// Model representing a system notification.
class AppNotification {
  final int id;
  final String type;
  final String title;
  final String description;
  final DateTime timestamp;
  final String status;
  final int? relatedUnitId;
  final int? relatedAssetId;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.status,
    this.relatedUnitId,
    this.relatedAssetId,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      status: json['status'] ?? '',
      relatedUnitId: json['related_unit_id'] != null
          ? (json['related_unit_id'] is int
              ? json['related_unit_id']
              : int.tryParse(json['related_unit_id'].toString()))
          : null,
      relatedAssetId: json['related_asset_id'] != null
          ? (json['related_asset_id'] is int
              ? json['related_asset_id']
              : int.tryParse(json['related_asset_id'].toString()))
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'description': description,
        'timestamp': timestamp.toIso8601String(),
        'status': status,
        'related_unit_id': relatedUnitId,
        'related_asset_id': relatedAssetId,
      };
}