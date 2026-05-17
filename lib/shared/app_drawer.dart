import 'package:cinduhrella/authentications/settings.dart';
import 'package:cinduhrella/screens/bulk_capture_page.dart';
import 'package:cinduhrella/screens/closet_scanner_page.dart';
import 'package:cinduhrella/screens/try_on_studio_page.dart';
import 'package:cinduhrella/shared/profile_avatar.dart';
import 'package:cinduhrella/services/auth_service.dart';
import 'package:cinduhrella/services/navigation_service.dart';
import 'package:cinduhrella/services/alert_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class AppDrawer extends StatelessWidget {
  final String userName;
  final String profileImageUrl;

  AppDrawer({required this.userName, required this.profileImageUrl, super.key});

  final AuthService _authService = GetIt.instance.get<AuthService>();
  final NavigationService _navigationService =
      GetIt.instance.get<NavigationService>();
  final AlertService _alertService = GetIt.instance.get<AlertService>();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.blue,
            ),
            child: Column(
              children: [
                ProfileAvatar(
                  radius: 40,
                  imageUrl: profileImageUrl,
                ),
                const SizedBox(height: 10),
                Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.document_scanner_outlined),
            title: const Text('Closet Scanner'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ClosetScannerPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_outdoor),
            title: const Text('Bulk Capture Closet'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BulkCapturePage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.accessibility_new),
            title: const Text('Try-On Studio'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TryOnStudioPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        const SettingsPage()), // Navigate to Settings Page
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('App Version'),
            subtitle: const Text('v1.0.0'),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Log Out'),
            onTap: () async {
              bool logOutResult = await _authService.logout();
              if (logOutResult) {
                _navigationService.pushReplacementNamed("/login");
                _alertService.showToast(
                    text: "Sad to see you leave!", icon: Icons.done);
              }
            },
          ),
        ],
      ),
    );
  }
}
