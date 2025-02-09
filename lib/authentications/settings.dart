import 'package:flutter/material.dart';
import 'package:cinduhrella/services/auth_service.dart';
import 'package:cinduhrella/services/navigation_service.dart';
import 'package:cinduhrella/services/alert_service.dart';
import 'package:get_it/get_it.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final GetIt _getIt = GetIt.instance;
  late AuthService _authService;
  late NavigationService _navigationService;
  late AlertService _alertService;
  String userEmail = "";
  String userPhone = "Not Set";

  @override
  void initState() {
    super.initState();
    _authService = _getIt.get<AuthService>();
    _navigationService = _getIt.get<NavigationService>();
    _alertService = _getIt.get<AlertService>();
    _fetchUserDetails();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchUserDetails(); // ✅ Refresh UI on dependencies change
  }

  Future<void> _fetchUserDetails() async {
    String? updatedEmail = await _authService.getEmail();
    String? updatedPhone =
        await _authService.getPhoneNumber(); // Fetch updated phone

    setState(() {
      userEmail = updatedEmail ?? "Not Available";
      userPhone = updatedPhone ?? "Not Set";
    });
  }

  void _changePassword() {
    _navigationService.pushNamed('/change-password');
  }

  void _setupTwoFA() async {
    final result = await _navigationService.pushNamedAndReturn('/setup-2fa');

    if (result == true) {
      _fetchUserDetails(); // ✅ Refresh phone number & 2FA status
    }
  }

  void _logout() async {
    bool result = await _authService.logout();
    if (result) {
      _navigationService.pushReplacementNamed('/login');
      _alertService.showToast(
          text: "You have been logged out.", icon: Icons.done);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text("Email"),
            subtitle: Text(userEmail),
          ),
          ListTile(
            leading: const Icon(Icons.phone),
            title: const Text("Phone Number"),
            subtitle: Text(userPhone),
          ),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text("Change Password"),
            onTap: _changePassword,
          ),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text("Set Up Two-Factor Authentication"),
            onTap: _setupTwoFA,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Log Out", style: TextStyle(color: Colors.red)),
            onTap: _logout,
          ),
        ],
      ),
    );
  }
}
