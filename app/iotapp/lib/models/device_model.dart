class Device {
  final String id;
  final String deviceName;
  final String location;
  final bool active;

  Device({
    required this.id,
    required this.deviceName,
    required this.location,
    required this.active,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['_id'] ?? '',
      deviceName: json['deviceName'] ?? 'Không tên',
      location: json['location'] ?? 'Không có vị trí',
      active: json['active'] ?? false,
    );
  }
}
