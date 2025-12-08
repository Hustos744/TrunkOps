class Asset {
  final int id;
  final String invNumber;
  final String type;
  final String model;
  final String unit;
  final String status;
  final String location;
  final String lastCheck;

  // Параметри для радіопланування
  final double? txPowerW; // потужність, Вт
  final double? frequencyMHz; // частота, МГц
  final double? antennaHeightM; // висота антени БС, м
  final double? antennaGainDb; // підсилення антени, дБ (опціонально)

  // Координати на мапі (WGS-84)
  final double? lat; // широта
  final double? lon; // довгота

  // Висота приймальної антени абонента (для моделі, опціонально)
  final double? rxHeightM;

  Asset({
    required this.id,
    required this.invNumber,
    required this.type,
    required this.model,
    required this.unit,
    required this.status,
    required this.location,
    required this.lastCheck,
    this.txPowerW,
    this.frequencyMHz,
    this.antennaHeightM,
    this.antennaGainDb,
    this.lat,
    this.lon,
    this.rxHeightM,
  });

  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      id: json['id'] as int,
      invNumber: json['invNumber'] as String,
      type: json['type'] as String,
      model: json['model'] as String,
      unit: json['unit'] as String,
      status: json['status'] as String,
      location: json['location'] as String,
      lastCheck: json['lastCheck'] as String,
      txPowerW: (json['txPowerW'] as num?)?.toDouble(),
      frequencyMHz: (json['frequencyMHz'] as num?)?.toDouble(),
      antennaHeightM: (json['antennaHeightM'] as num?)?.toDouble(),
      antennaGainDb: (json['antennaGainDb'] as num?)?.toDouble(),
      lat: (json['lat'] as num?)?.toDouble(),
      lon: (json['lon'] as num?)?.toDouble(),
      rxHeightM: (json['rxHeightM'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invNumber': invNumber,
      'type': type,
      'model': model,
      'unit': unit,
      'status': status,
      'location': location,
      'lastCheck': lastCheck,
      'txPowerW': txPowerW,
      'frequencyMHz': frequencyMHz,
      'antennaHeightM': antennaHeightM,
      'antennaGainDb': antennaGainDb,
      'lat': lat,
      'lon': lon,
      'rxHeightM': rxHeightM,
    };
  }

  Asset copyWith({
    int? id,
    String? invNumber,
    String? type,
    String? model,
    String? unit,
    String? status,
    String? location,
    String? lastCheck,
    double? txPowerW,
    double? frequencyMHz,
    double? antennaHeightM,
    double? antennaGainDb,
    double? lat,
    double? lon,
    double? rxHeightM,
  }) {
    return Asset(
      id: id ?? this.id,
      invNumber: invNumber ?? this.invNumber,
      type: type ?? this.type,
      model: model ?? this.model,
      unit: unit ?? this.unit,
      status: status ?? this.status,
      location: location ?? this.location,
      lastCheck: lastCheck ?? this.lastCheck,
      txPowerW: txPowerW ?? this.txPowerW,
      frequencyMHz: frequencyMHz ?? this.frequencyMHz,
      antennaHeightM: antennaHeightM ?? this.antennaHeightM,
      antennaGainDb: antennaGainDb ?? this.antennaGainDb,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      rxHeightM: rxHeightM ?? this.rxHeightM,
    );
  }
}
