import 'dart:convert';

/// Single base station (site) used for coverage calculation.
class Site {
  final String id;
  final double lat;
  final double lon;
  final double txPowerDbm;
  final double antennaGainDbi;
  final double antennaHeightM;
  final double frequencyMhz;

  Site({
    required this.id,
    required this.lat,
    required this.lon,
    required this.txPowerDbm,
    required this.antennaGainDbi,
    required this.antennaHeightM,
    required this.frequencyMhz,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'lat': lat,
        'lon': lon,
        'tx_power_dbm': txPowerDbm,
        'antenna_gain_dbi': antennaGainDbi,
        'antenna_height_m': antennaHeightM,
        'frequency_mhz': frequencyMhz,
      };
}

class GridConfig {
  final double centerLat;
  final double centerLon;
  final double radiusKm;
  final double stepM;

  GridConfig({
    required this.centerLat,
    required this.centerLon,
    required this.radiusKm,
    required this.stepM,
  });

  Map<String, dynamic> toJson() => {
        'center_lat': centerLat,
        'center_lon': centerLon,
        'radius_km': radiusKm,
        'step_m': stepM,
      };
}

class CoverageRequest {
  final List<Site> sites;
  final double rxHeightM;
  final GridConfig grid;
  final String model;

  CoverageRequest({
    required this.sites,
    required this.rxHeightM,
    required this.grid,
    this.model = 'hata',
  });

  Map<String, dynamic> toJson() => {
        'sites': sites.map((s) => s.toJson()).toList(),
        'rx_height_m': rxHeightM,
        'grid': grid.toJson(),
        'model': model,
      };

  String toJsonString() => jsonEncode(toJson());
}

class CoverageCell {
  final double lat;
  final double lon;
  final double rxLevelDbm;

  CoverageCell({
    required this.lat,
    required this.lon,
    required this.rxLevelDbm,
  });

  factory CoverageCell.fromJson(Map<String, dynamic> json) => CoverageCell(
        lat: (json['lat'] as num).toDouble(),
        lon: (json['lon'] as num).toDouble(),
        rxLevelDbm: (json['rx_level_dbm'] as num).toDouble(),
      );
}

class CoverageResponse {
  final double gridStepM;
  final List<CoverageCell> cells;

  CoverageResponse({required this.gridStepM, required this.cells});

  factory CoverageResponse.fromJson(Map<String, dynamic> json) {
    final cellsJson = json['cells'] as List<dynamic>? ?? [];
    return CoverageResponse(
      gridStepM: (json['grid_step_m'] as num).toDouble(),
      cells: cellsJson
          .map((e) => CoverageCell.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
