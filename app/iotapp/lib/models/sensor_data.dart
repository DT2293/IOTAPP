class SensorData {
  final double averageTemperature;
  final double averageHumidity;
  final int averageSmokeLevel;
  final bool flameDetected;
  final DateTime date;

  SensorData({
    required this.averageTemperature,
    required this.averageHumidity,
    required this.averageSmokeLevel,
    required this.flameDetected,
    required this.date,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      averageTemperature: (json['averageTemperature'] ?? 0).toDouble(),
      averageHumidity: (json['averageHumidity'] ?? 0).toDouble(),
      averageSmokeLevel: (json['averageSmokeLevel'] ?? 0).toInt(),
      flameDetected: json['flameDetected'] ?? false,
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
    );
  }
}
