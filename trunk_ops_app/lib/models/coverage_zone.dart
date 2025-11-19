/// Model representing a coverage zone associated with a network node.
///
/// The geometry is expected to be a GeoJSON string or WKT returned by the API.
class CoverageZone {
  final int id;
  final int nodeId;
  final String geometry;
  final DateTime createdAt;

  CoverageZone({
    required this.id,
    required this.nodeId,
    required this.geometry,
    required this.createdAt,
  });

  factory CoverageZone.fromJson(Map<String, dynamic> json) {
    return CoverageZone(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      nodeId: json['node_id'] is int
          ? json['node_id']
          : int.tryParse(json['node_id'].toString()) ?? 0,
      geometry: json['geometry'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? json['createdAt'] ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'node_id': nodeId,
        'geometry': geometry,
        'created_at': createdAt.toIso8601String(),
      };
}