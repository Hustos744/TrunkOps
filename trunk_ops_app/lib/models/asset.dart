/// Model representing an equipment asset.
class Asset {
  final int id;
  final String inventoryNumber;
  final String type;
  final String model;
  final int? assignedUnitId;
  final String status;
  final String location;
  final DateTime? lastCheckDate;

  Asset({
    required this.id,
    required this.inventoryNumber,
    required this.type,
    required this.model,
    this.assignedUnitId,
    required this.status,
    required this.location,
    this.lastCheckDate,
  });

  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      inventoryNumber: json['inventory_number'] ?? json['inventoryNumber'] ?? '',
      type: json['type'] ?? '',
      model: json['model'] ?? '',
      assignedUnitId: json['assigned_unit_id'] != null
          ? (json['assigned_unit_id'] is int
              ? json['assigned_unit_id']
              : int.tryParse(json['assigned_unit_id'].toString()))
          : null,
      status: json['status'] ?? '',
      location: json['location'] ?? '',
      lastCheckDate: json['last_check_date'] != null
          ? DateTime.tryParse(json['last_check_date'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'inventory_number': inventoryNumber,
        'type': type,
        'model': model,
        'assigned_unit_id': assignedUnitId,
        'status': status,
        'location': location,
        'last_check_date': lastCheckDate?.toIso8601String(),
      };
}