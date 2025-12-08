import 'dart:convert';

/// Опис однієї базової станції (сайту) для розрахунку покриття.
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

  factory Site.fromJson(Map<String, dynamic> json) => Site(
    id: json['id'] as String,
    lat: (json['lat'] as num).toDouble(),
    lon: (json['lon'] as num).toDouble(),
    txPowerDbm: (json['tx_power_dbm'] as num).toDouble(),
    antennaGainDbi: (json['antenna_gain_dbi'] as num).toDouble(),
    antennaHeightM: (json['antenna_height_m'] as num).toDouble(),
    frequencyMhz: (json['frequency_mhz'] as num).toDouble(),
  );
}

/// Конфігурація сітки точок, де рахується покриття.
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

  factory GridConfig.fromJson(Map<String, dynamic> json) => GridConfig(
    centerLat: (json['center_lat'] as num).toDouble(),
    centerLon: (json['center_lon'] as num).toDouble(),
    radiusKm: (json['radius_km'] as num).toDouble(),
    stepM: (json['step_m'] as num).toDouble(),
  );
}

/// Запит на розрахунок покриття.
/// Використовується і беком (якщо захочеш), і може бути збережений у JSON.
class CoverageRequest {
  final List<Site> sites;
  final double rxHeightM;
  final GridConfig grid;
  final String model; // наприклад: 'hata', 'cost231' тощо

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

  factory CoverageRequest.fromJson(Map<String, dynamic> json) =>
      CoverageRequest(
        sites: (json['sites'] as List<dynamic>)
            .map((e) => Site.fromJson(e as Map<String, dynamic>))
            .toList(),
        rxHeightM: (json['rx_height_m'] as num).toDouble(),
        grid: GridConfig.fromJson(json['grid'] as Map<String, dynamic>),
        model: json['model'] as String? ?? 'hata',
      );
}

/// Одна точка сітки з розрахованим рівнем сигналу.
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

  Map<String, dynamic> toJson() => {
    'lat': lat,
    'lon': lon,
    'rx_level_dbm': rxLevelDbm,
  };
}

/// Відповідь з результатами розрахунку покриття.
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

  Map<String, dynamic> toJson() => {
    'grid_step_m': gridStepM,
    'cells': cells.map((c) => c.toJson()).toList(),
  };

  String toJsonString() => jsonEncode(toJson());
}
