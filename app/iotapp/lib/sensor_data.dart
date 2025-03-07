class SensorData {
  final double temperature;
  final int humidity;
  final int smoke;

  SensorData({required this.temperature, required this.humidity, required this.smoke});

  // Chuyển JSON thành Object
  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      temperature: json['temperature'].toDouble(),
      humidity: json['humidity'].toInt(),
      smoke: json['smoke'].toInt(),
    );
  }
}
