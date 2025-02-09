import 'package:flutter/material.dart';
import 'package:cinduhrella/services/auth_service.dart';
import 'package:cinduhrella/services/alert_service.dart';
import 'package:get_it/get_it.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final GetIt _getIt = GetIt.instance;
  late AuthService _authService;
  late AlertService _alertService;
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _authService = _getIt.get<AuthService>();
    _alertService = _getIt.get<AlertService>();
  }

  void _changePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _alertService.showToast(
          text: "Passwords do not match!", icon: Icons.error);
      return;
    }

    setState(() {
      isLoading = true;
    });

    bool success =
        await _authService.changePassword(_newPasswordController.text);

    setState(() {
      isLoading = false;
    });

    if (success) {
      _alertService.showToast(
          text: "Password changed successfully!", icon: Icons.done);
      Navigator.pop(context);
    } else {
      _alertService.showToast(
          text: "Failed to change password.", icon: Icons.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Change Password")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _newPasswordController,
              decoration: const InputDecoration(labelText: "New Password"),
              obscureText: true,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(labelText: "Confirm Password"),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : _changePassword,
              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text("Change Password"),
            ),
          ],
        ),
      ),
    );
  }
}
