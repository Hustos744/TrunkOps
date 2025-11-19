/// Model representing a maintenance task for equipment or nodes.
class MaintenanceTask {
  final int id;
  final String title;
  final DateTime? plannedDate;
  final String status;
  final String statusLabel;
  final String description;
  final int? assignedUnitId;
  final int? assetId;

  MaintenanceTask({
    required this.id,
    required this.title,
    this.plannedDate,
    required this.status,
    required this.statusLabel,
    required this.description,
    this.assignedUnitId,
    this.assetId,
  });

  factory MaintenanceTask.fromJson(Map<String, dynamic> json) {
    return MaintenanceTask(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      title: json['title'] ?? '',
      plannedDate: json['planned_date'] != null
          ? DateTime.tryParse(json['planned_date'])
          : null,
      status: json['status'] ?? '',
      statusLabel: json['status_label'] ?? json['statusLabel'] ?? '',
      description: json['description'] ?? '',
      assignedUnitId: json['assigned_unit_id'] != null
          ? (json['assigned_unit_id'] is int
              ? json['assigned_unit_id']
              : int.tryParse(json['assigned_unit_id'].toString()))
          : null,
      assetId: json['asset_id'] != null
          ? (json['asset_id'] is int
              ? json['asset_id']
              : int.tryParse(json['asset_id'].toString()))
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'planned_date': plannedDate?.toIso8601String(),
        'status': status,
        'status_label': statusLabel,
        'description': description,
        'assigned_unit_id': assignedUnitId,
        'asset_id': assetId,
      };
}