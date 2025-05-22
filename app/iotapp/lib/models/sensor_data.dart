class SensorData {
  final DateTime time;
  final double temperature;
  final double humidity;
  final double smoke;

  SensorData({
    required this.time,
    required this.temperature,
    required this.humidity,
    required this.smoke,
  });
}

List<SensorData> mockSensorData = List.generate(20, (index) {
  final now = DateTime.now();
  return SensorData(
    time: now.subtract(Duration(minutes: 20 - index)),
    temperature: 20 + index * 0.5,
    humidity: 60 - index * 0.3,
    smoke: 30 + (index % 5) * 2.0,
  );
});
