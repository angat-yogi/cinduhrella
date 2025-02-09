import 'package:cinduhrella/authentications/settings.dart';
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
                CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage(profileImageUrl),
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
