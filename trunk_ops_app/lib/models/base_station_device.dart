class BaseStationDevice {
  final String id;
  final String name;
  final double lat;
  final double lon;
  final double txPowerDbm;
  final double antennaGainDbi;
  final double antennaHeightM;
  final double frequencyMhz;

  const BaseStationDevice({
    required this.id,
    required this.name,
    required this.lat,
    required this.lon,
    required this.txPowerDbm,
    required this.antennaGainDbi,
    required this.antennaHeightM,
    required this.frequencyMhz,
  });
}
