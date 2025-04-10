// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:iotapp/pages/devicedetail_page.dart';
// import 'package:iotapp/pages/profile_page.dart';
// import 'package:iotapp/pages/setting_page.dart';
// import 'package:iotapp/provider/language_provider.dart';
// import '../services/auth_service.dart';
// import 'login_page.dart';

// // class HomePage extends  StatefulWidget {
// //   @override
// //   _HomePageState createState() => _HomePageState();
// // }
// class HomePage extends ConsumerStatefulWidget {

//   const HomePage(
//       {super.key});

//   @override
//   ConsumerState<HomePage> createState() => _State();
// }

// class _State extends ConsumerState<HomePage> {
// //class _HomePageState extends State<HomePage> {
//   final AuthService _authService = AuthService();
//   String? _token;
//   String? _userId;
//   String? _username;
//   String? _email;
//   List<dynamic> _devices = [];
//   @override
//   void initState() {
//     super.initState();
//     _loadUserData();
//   }

//   void _loadUserData() async {
//     String? token = await _authService.getToken();
//     Map<String, dynamic>? userData = await _authService.getUserInfo();
//     List<String> devices =
//         await _authService.getUserDevices(); // ✅ Lấy danh sách thiết bị

//     print("Token: $token"); // ✅ Debug token
//     print("User data: $userData"); // ✅ Debug user info
//     print("Devices: $devices"); // ✅ Debug danh sách thiết bị

//     setState(() {
//       _token = token;
//       _userId = userData?["_id"] ?? "Không có dữ liệu";
//       _username = userData?["username"] ?? "Không có dữ liệu";
//       _email = userData?["email"] ?? "Không có dữ liệu";
//       _devices = devices; // ✅ Cập nhật danh sách thiết bị
//     });
//   }

//   void _logout() async {
//     await _authService.logout();
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(builder: (context) => LoginPage()),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final languageId = ref.watch(languageProvider);
//     final textMap = ref.watch(textMapProvider);
//     final currentText = textMap[languageId]?["mainview.HomePage"] ?? "N/A";
//     final profile = textMap[languageId]?["mainview.Profile"] ?? "N/A";
//   //   final setting = textMap[languageId]?["mainview.Setting"] ?? "N/A";
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(currentText),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.logout),
//             onPressed: _logout,
//           )
//         ],
//       ),
//       drawer: Drawer(
//         child: Column(
//           children: [
//             UserAccountsDrawerHeader(
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [Colors.blue.shade700, Colors.blue.shade900],
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                 ),
//               ),
//               accountName: Text(
//                 _username ?? "Không có dữ liệu",
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//               accountEmail: Text(_email ?? "Không có dữ liệu"),
//               currentAccountPicture: CircleAvatar(
//                 backgroundColor: Colors.white,
//                 child: Text(
//                   _username != null ? _username![0].toUpperCase() : "U",
//                   style: TextStyle(
//                       fontSize: 24,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.blue),
//                 ),
//               ),
//             ),
//             Expanded(
//               child: ListView(
//                 children: [
//                   ListTile(
//                     leading: Icon(Icons.home, color: Colors.blue),
//                     title: Text(currentText),
//                     onTap: () => Navigator.pop(context),
//                   ),
//                   ListTile(
//                     leading: Icon(Icons.person, color: Colors.blue),
//                     title: Text(profile),
//                     onTap: () async {
//                       // Lấy token và thông tin người dùng
//                       String? token = await _authService.getToken();
//                       Map<String, dynamic>? userData =
//                           await _authService.getUserInfo();

//                       if (userData != null && token != null) {
//                         Navigator.pushReplacement(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) => ProfilePage(
//                               userId: userData["userId"] ?? "",
//                               username: userData["username"] ?? "",
//                               email: userData["email"] ?? "",
//                               token: token,
//                             ),
//                           ),
//                         );
//                       } else {
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           SnackBar(
//                               content:
//                                   Text("Không lấy được thông tin người dùng!")),
//                         );
//                       }
//                     },
//                   ),
//                   ListTile(
//   leading: Icon(Icons.settings, color: Colors.blue),
//   title: Text("Setting"),
//   onTap: () {
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (context) => SettingPage()),
//     );
//   },
// ),

//                   Divider(),
//                   ListTile(
//                     leading: Icon(Icons.exit_to_app, color: Colors.red),
//                     title:
//                         Text("Đăng xuất", style: TextStyle(color: Colors.red)),
//                     onTap: _logout,
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text("Danh sách thiết bị:",
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//             SizedBox(height: 10),
//             Expanded(
//               child: _devices.isEmpty
//                   ? Center(
//                       child: Text(
//                           "Không có thiết bị nào")) // ✅ Hiển thị khi không có thiết bị
//                   : ListView.builder(
//                       itemCount: _devices.length,
//                       itemBuilder: (context, index) {
//                         return Card(
//                           child: ListTile(
//                             leading: Icon(Icons.devices, color: Colors.green),
//                             title: Text("Thiết bị: ${_devices[index]}"),
//                             onTap: () async {
//                               String? userToken = await _authService.getToken();

//                               if (userToken != null) {
//                                 Navigator.push(
//                                   context,
//                                   MaterialPageRoute(
//                                     builder: (context) => DeviceDetailPage(
//                                       deviceId: _devices[
//                                           index], // ✅ Truyền deviceId đúng
//                                       userToken:
//                                           userToken, // ✅ Truyền token vào DeviceDetailPage
//                                     ),
//                                   ),
//                                 );
//                               } else {
//                                 ScaffoldMessenger.of(context).showSnackBar(
//                                   SnackBar(
//                                       content: Text(
//                                           "Không tìm thấy token, vui lòng đăng nhập lại!")),
//                                 );
//                               }
//                               print("Nhấn vào thiết bị: ${_devices[index]}");
//                             },
//                           ),
//                         );
//                       },
//                     ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iotapp/pages/devicedetail_page.dart';
import 'package:iotapp/pages/profile_page.dart';
import 'package:iotapp/pages/setting_page.dart';

import 'package:iotapp/services/auth_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'login_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final AuthService _authService = AuthService();
  String? _token;
  String? _userId;
  String? _username;
  String? _email;
  List<dynamic> _devices = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    String? token = await _authService.getToken();
    Map<String, dynamic>? userData = await _authService.getUserInfo();
    List<String> devices = await _authService.getUserDevices();

    setState(() {
      _token = token;
      _userId = userData?["_id"] ?? "Không có dữ liệu";
      _username = userData?["username"] ?? "Không có dữ liệu";
      _email = userData?["email"] ?? "Không có dữ liệu";
      _devices = devices;
    });
  }

  void _logout() async {
    await _authService.logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('home')),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          )
        ],
      ),
  drawer: Drawer(
  child: Column(
    children: [
      UserAccountsDrawerHeader(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade700, Colors.blue.shade900],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        accountName: Text(
          _username ?? tr('no_data'),  // Dùng localization key cho giá trị mặc định
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        accountEmail: Text(_email ?? tr('no_data')),  // Dùng localization key cho giá trị mặc định
        currentAccountPicture: CircleAvatar(
          backgroundColor: Colors.white,
          child: Text(
            _username != null ? _username![0].toUpperCase() : "U",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
        ),
      ),
      Expanded(
        child: ListView(
          children: [
            ListTile(
              leading: Icon(Icons.home, color: Colors.blue),
              title: Text(tr('home')),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.person, color: Colors.blue),
              title: Text(tr('profile')),
              onTap: () async {
                String? token = await _authService.getToken();
                Map<String, dynamic>? userData = await _authService.getUserInfo();

                if (userData != null && token != null) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfilePage(
                        userId: userData["userId"] ?? "",
                        username: userData["username"] ?? "",
                        email: userData["email"] ?? "",
                        token: token,
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(tr('user_info_error'))),
                  );
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.settings, color: Colors.blue),
              title: Text(tr('settings')),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingPage()),
                );
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.exit_to_app, color: Colors.red),
              title: Text(tr('logout'), style: TextStyle(color: Colors.red)),
              onTap: _logout,
            ),
          ],
        ),
      ),
    ],
  ),
),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr("device_list"), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Expanded(
              child: _devices.isEmpty
                  ? Center(child: Text(tr("no_devices")))
                  : ListView.builder(
                      itemCount: _devices.length,
                      itemBuilder: (context, index) {
                        return Card(
                          child: ListTile(
                            leading: Icon(Icons.devices, color: Colors.green),
                            title: Text("${tr("device")}: ${_devices[index]}"),
                            onTap: () async {
                              String? userToken = await _authService.getToken();
                              if (userToken != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DeviceDetailPage(
                                      deviceId: _devices[index],
                                      userToken: userToken,
                                    ),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(tr("token_error"))),
                                );
                              }
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
