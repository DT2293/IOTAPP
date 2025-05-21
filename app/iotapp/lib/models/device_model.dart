class Device {
  final String deviceId;  // đúng rồi, string
  final String deviceName;
  final String location;
  final bool active;

  Device({
    required this.deviceId,
    required this.deviceName,
    required this.location,
    required this.active,
  });

  factory Device.fromJson(Map<String, dynamic> json) => Device(
    deviceId: json['deviceId'] as String,
    deviceName: json['deviceName'] as String,
    location: json['location'] as String,
    active: json['active'] as bool,
  );

  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'deviceName': deviceName,
    'location': location,
    'active': active,
  };
}
