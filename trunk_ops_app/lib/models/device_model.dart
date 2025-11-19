/// Model representing a radio or device model.
class DeviceModel {
  final int id;
  final String name;
  final String? description;

  DeviceModel({
    required this.id,
    required this.name,
    this.description,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) => DeviceModel(
        id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
        name: json['name'] ?? '',
        description: json['description'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
      };
}