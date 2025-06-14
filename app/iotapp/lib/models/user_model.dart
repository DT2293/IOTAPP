

class User {
  final String? id;
  final String? username;
  final String? email;
  final String? password;
  final List<String> phonenumber;
  final List<String>? devices;

  User({
    this.id,
    required this.username,
    required this.email,
    required this.phonenumber,
    this.password,
    this.devices,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'],
      username: json['username'],
      email: json['email'],
      phonenumber: List<String>.from(json['phonenumber'] ?? []),
      devices: json['devices'] != null ? List<String>.from(json['devices']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      if (password != null) 'password': password,
    };
  }
}
