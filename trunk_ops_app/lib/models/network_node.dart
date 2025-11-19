/// Model representing a network node (e.g. repeater or radio site).
class NetworkNode {
  final int id;
  final String name;
  final double? latitude;
  final double? longitude;
  final double? height;
  final String? description;

  NetworkNode({
    required this.id,
    required this.name,
    this.latitude,
    this.longitude,
    this.height,
    this.description,
  });

  factory NetworkNode.fromJson(Map<String, dynamic> json) {
    return NetworkNode(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
      height: json['height'] != null
          ? double.tryParse(json['height'].toString())
          : null,
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'height': height,
      'description': description,
    };
  }
}