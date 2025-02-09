import 'package:flutter/material.dart';
import 'package:cinduhrella/services/auth_service.dart';
import 'package:cinduhrella/services/alert_service.dart';
import 'package:get_it/get_it.dart';

class Setup2FAPage extends StatefulWidget {
  const Setup2FAPage({super.key});

  @override
  State<Setup2FAPage> createState() => _Setup2FAPageState();
}

class _Setup2FAPageState extends State<Setup2FAPage> {
  final GetIt _getIt = GetIt.instance;
  late AuthService _authService;
  late AlertService _alertService;
  bool is2FAEnabled = false;
  bool isLoading = false;
  String selected2FAOption = "email"; // Default option
  String? phoneNumber;
  String? email;

  @override
  void initState() {
    super.initState();
    _authService = _getIt.get<AuthService>();
    _alertService = _getIt.get<AlertService>();
    _fetch2FAStatus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetch2FAStatus(); // Refresh UI on dependencies change
  }

  Future<void> _fetch2FAStatus() async {
    bool status = await _authService.is2FAEnabled();
    String option =
        await _authService.get2FAOption(); // Fetch stored 2FA option
    String? userPhone = await _authService.getPhoneNumber();
    String? userEmail = await _authService.getEmail();
    setState(() {
      is2FAEnabled = status;
      selected2FAOption = option;
      phoneNumber = userPhone;
      email = userEmail;
    });
  }

  void _verifyBeforeDisable2FA() {
    TextEditingController otpController = TextEditingController();
    bool otpSent = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(otpSent
                  ? "Enter OTP to Disable 2FA"
                  : "Verify to Disable 2FA"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!otpSent)
                    Text(
                        "An OTP will be sent to your registered phone number."),
                  if (otpSent)
                    TextField(
                      controller: otpController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: "Enter OTP"),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () async {
                    if (!otpSent) {
                      // ✅ Step 1: Send OTP
                      String fullPhoneNumber = phoneNumber!;
                      if (!fullPhoneNumber.startsWith("+")) {
                        String? storedCountryCode =
                            await _authService.getCountryCode();
                        fullPhoneNumber =
                            "${storedCountryCode ?? "+1"}$fullPhoneNumber";
                      }
                      bool success = await _authService
                          .sendOTPToDisable2FA(fullPhoneNumber);
                      if (success) {
                        setState(() {
                          otpSent = true;
                        });
                        _alertService.showToast(
                            text: "OTP sent to $fullPhoneNumber",
                            icon: Icons.message);
                      } else {
                        _alertService.showToast(
                            text: "Failed to send OTP.", icon: Icons.error);
                      }
                    } else {
                      // ✅ Step 2: Verify OTP and disable 2FA
                      bool verified = await _authService
                          .verifyOTPToDisable2FA(otpController.text);

                      if (verified) {
                        bool success =
                            await _authService.set2FA(false, "phone");
                        if (success) {
                          // ✅ Immediately update state so toggle reflects change
                          setState(() {
                            is2FAEnabled = false;
                            phoneNumber = null;
                          });

                          _alertService.showToast(
                              text: "2FA disabled successfully!",
                              icon: Icons.done);

                          // ✅ Close dialog and refresh UI
                          Navigator.pop(context, true);
                        }
                      } else {
                        _alertService.showToast(
                            text: "Invalid OTP.", icon: Icons.error);
                      }
                    }
                  },
                  child: Text(otpSent ? "Verify & Disable" : "Send OTP"),
                ),
              ],
            );
          },
        );
      },
    ).then((value) {
      if (value == true) {
        _fetch2FAStatus();
      }
    });
  }

  void _toggle2FA() async {
    if (email == null && phoneNumber == null) {
      _alertService.showToast(
        text:
            "Please add and verify either an email or a phone number before enabling 2FA.",
        icon: Icons.error,
      );
      return;
    }

    if (is2FAEnabled && selected2FAOption == "phone") {
      _verifyBeforeDisable2FA();
      return;
    }

    setState(() {
      isLoading = true;
    });

    bool success = await _authService.set2FA(!is2FAEnabled, selected2FAOption);

    if (success) {
      setState(() {
        is2FAEnabled = !is2FAEnabled; // ✅ Update UI immediately
      });
      Navigator.pop(context, true);
    } else {
      _alertService.showToast(text: "Failed to update 2FA.", icon: Icons.error);
    }

    setState(() {
      isLoading = false;
    });
  }

  void _set2FAOption(String? option) {
    if (option != null) {
      setState(() {
        selected2FAOption = option;
      });
    }
  }

  void _addPhoneNumber() {
    TextEditingController phoneController = TextEditingController();
    TextEditingController otpController = TextEditingController();
    bool otpSent = false; // Track OTP step
    String selectedCountryCode = "+1"; // Default to USA

    // List of country codes (You can expand this list)
    final List<Map<String, String>> countryCodes = [
      {"name": "United States", "code": "+1"},
      {"name": "Canada", "code": "+1"},
      {"name": "United Kingdom", "code": "+44"},
      {"name": "India", "code": "+91"},
      {"name": "Australia", "code": "+61"},
      {"name": "Germany", "code": "+49"},
      {"name": "France", "code": "+33"},
      {"name": "Brazil", "code": "+55"},
    ];

    final uniqueCountryCodes = {
      for (var country in countryCodes) country["code"]: country
    }.values.toList();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(otpSent ? "Enter OTP" : "Add Phone Number"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!otpSent) ...[
                    // Country Code Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedCountryCode,
                      decoration:
                          const InputDecoration(labelText: "Country Code"),
                      items: uniqueCountryCodes.map((country) {
                        return DropdownMenuItem(
                          value: country["code"],
                          child:
                              Text("${country["name"]} (${country["code"]})"),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          selectedCountryCode = newValue!;
                        });
                      },
                    ),
                    const SizedBox(height: 10),

                    // Phone Number Input
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: "Enter your phone number",
                      ),
                    ),
                  ],
                  if (otpSent)
                    TextField(
                      controller: otpController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: "Enter OTP"),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () async {
                    if (!otpSent) {
                      String fullPhoneNumber =
                          "$selectedCountryCode${phoneController.text.trim()}";

                      // Step 1: Send OTP
                      bool success =
                          await _authService.sendOTP(fullPhoneNumber);
                      if (success) {
                        setState(() {
                          otpSent = true; // Move to OTP step
                        });
                        _alertService.showToast(
                            text: "OTP sent to $fullPhoneNumber",
                            icon: Icons.message);
                      } else {
                        _alertService.showToast(
                            text: "Failed to send OTP.", icon: Icons.error);
                      }
                    } else {
                      // Step 2: Verify OTP
                      bool verified =
                          await _authService.verifyAndSetPhoneNumber(
                              otpController.text, phoneController.text.trim());

                      if (verified) {
                        setState(() {
                          phoneNumber =
                              "$selectedCountryCode${phoneController.text.trim()}";
                        });
                        _alertService.showToast(
                            text: "Phone number added successfully!",
                            icon: Icons.done);
                        Navigator.pop(context);
                        Navigator.pop(context, true);
                      } else {
                        _alertService.showToast(
                            text: "Invalid OTP.", icon: Icons.error);
                      }
                    }
                  },
                  child: Text(otpSent ? "Verify OTP" : "Send OTP"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _addEmail() {
    TextEditingController emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Email"),
          content: TextField(
            controller: emailController,
            decoration: const InputDecoration(hintText: "Enter your email"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                bool success =
                    await _authService.verifyAndSetEmail(emailController.text);
                if (success) {
                  setState(() {
                    email = emailController.text;
                  });
                  _alertService.showToast(
                      text: "Email added successfully!", icon: Icons.done);
                } else {
                  _alertService.showToast(
                      text: "Failed to verify email.", icon: Icons.error);
                }
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Two-Factor Authentication")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.security),
              title: const Text("Enable Two-Factor Authentication"),
              trailing: Switch(
                value: is2FAEnabled,
                onChanged: isLoading ? null : (value) => _toggle2FA(),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              title: const Text("Select 2FA Method"),
              subtitle: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text("Email"),
                          value: "email",
                          groupValue: selected2FAOption,
                          onChanged: email != null ? _set2FAOption : null,
                        ),
                      ),
                      if (email == null)
                        ElevatedButton(
                          onPressed: _addEmail,
                          child: const Text("Add Email"),
                        ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text("Phone Number"),
                          value: "phone",
                          groupValue: selected2FAOption,
                          onChanged: phoneNumber != null ? _set2FAOption : null,
                        ),
                      ),
                      if (phoneNumber == null)
                        ElevatedButton(
                          onPressed: _addPhoneNumber,
                          child: const Text("Add Phone"),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
