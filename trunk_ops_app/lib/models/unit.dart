/// Model representing a military unit or group.
///
/// Instances of [Unit] are created from JSON returned by the backend API.
class Unit {
  final int id;
  final String name;
  final String type;
  final String area;
  final String status;
  final String statusLabel;
  final String activity;

  Unit({
    required this.id,
    required this.name,
    required this.type,
    required this.area,
    required this.status,
    required this.statusLabel,
    required this.activity,
  });

  factory Unit.fromJson(Map<String, dynamic> json) {
    return Unit(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      area: json['area'] ?? '',
      status: json['status'] ?? '',
      statusLabel: json['status_label'] ?? json['statusLabel'] ?? '',
      activity: json['activity'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'area': area,
      'status': status,
      'statusLabel': statusLabel,
      'activity': activity,
    };
  }
}