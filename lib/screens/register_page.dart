import 'package:cinduhrella/const.dart';
import 'package:cinduhrella/models/user_profile.dart';
import 'package:cinduhrella/services/alert_service.dart';
import 'package:cinduhrella/services/auth_service.dart';
import 'package:cinduhrella/services/database_service.dart';
import 'package:cinduhrella/services/media_service.dart';
import 'package:cinduhrella/services/navigation_service.dart';
import 'package:cinduhrella/services/storage_service.dart';
import 'package:cinduhrella/shared/custom_form_field.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'dart:io';

import 'package:logger/logger.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final Logger _logger = Logger();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GetIt _getIt = GetIt.instance;
  late AuthService _authService;
  late NavigationService _navigationService;
  late AlertService _alertService;
  late MediaService _mediaService;
  late StorageService _storageService;
  late DatabaseService _databaseService;
  bool isLoading = false;

  String? email, password, username, fullname, confirmPassword;
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _authService = _getIt.get<AuthService>();
    _navigationService = _getIt.get<NavigationService>();
    _alertService = _getIt.get<AlertService>();
    _mediaService = _getIt.get<MediaService>();
    _storageService = _getIt.get<StorageService>();
    _databaseService = _getIt.get<DatabaseService>();
  }

  void _register() async {
    try {
      setState(() {
        isLoading = true;
      });

      if (_formKey.currentState!.validate()) {
        _formKey.currentState!.save();

        // ✅ Register User
        bool result = await _authService.signUp(email!, password!);
        if (!result) {
          throw Exception("Unable to register user");
        }

        String? profilePicture;
        if (_profileImage != null) {
          // ✅ Upload profile image
          profilePicture = await _storageService.uploadImages(
            file: _profileImage!,
            uid: _authService.user!.uid,
          );
        }

        // ✅ Create User Profile in Firestore
        await _databaseService.createUserProfile(
          userProfile: UserProfile(
            uid: _authService.user!.uid,
            fullName: fullname ?? "Unknown User",
            userName: username ?? "user_${_authService.user!.uid}",
            profilePictureUrl:
                profilePicture ?? "https://example.com/default-profile.png",
            following: [], // ✅ Ensure new users start with an empty following list
          ),
        );

        // ✅ Navigate to Home Page
        _navigationService.goBack();
        _navigationService.pushReplacementNamed("/home");

        _alertService.showToast(
          text: "Registration Successful",
          icon: Icons.check_circle,
        );
      }
    } catch (e) {
      _logger.e("Registration Error: $e");
      _alertService.showToast(
        text: "Failed to register. Try again!",
        icon: Icons.error,
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: _buildUI(),
    );
  }

  Widget _buildUI() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 20.0),
        child: Column(
          children: [
            _headerText(),
            if (!isLoading) _registrationForm(),
            if (!isLoading) _loginAccountLink(),
            if (isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _headerText() {
    return SizedBox(
      width: MediaQuery.sizeOf(context).width,
      child: const Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            "Create Your Account",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          Text(
            "Join us and enjoy your experience",
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w500, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _registrationForm() {
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.6,
      margin: EdgeInsets.symmetric(
          vertical: MediaQuery.sizeOf(context).height * 0.05),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _pfpSelectionFiled(),
            CustomFormField(
              onSaved: (value) => username = value,
              obscureText: false,
              validationRegExp: userNamePattern,
              hintPlaceHolder: "Username",
              height: MediaQuery.sizeOf(context).height * 0.1,
            ),
            CustomFormField(
              onSaved: (value) => fullname = value,
              obscureText: false,
              validationRegExp: namePattern,
              hintPlaceHolder: " Full Name",
              height: MediaQuery.sizeOf(context).height * 0.1,
            ),
            CustomFormField(
              onSaved: (value) => email = value,
              obscureText: false,
              validationRegExp: emailPattern,
              hintPlaceHolder: "Email",
              height: MediaQuery.sizeOf(context).height * 0.1,
            ),
            CustomFormField(
              onSaved: (value) => password = value,
              obscureText: true,
              validationRegExp: passwordPattern,
              hintPlaceHolder: "Password",
              height: MediaQuery.sizeOf(context).height * 0.1,
            ),
            _registerButton(),
          ],
        ),
      ),
    );
  }

  Widget _pfpSelectionFiled() {
    return GestureDetector(
      onTap: () async {
        File? file = await _mediaService.getImageFromGallery();
        if (file != null) {
          setState(() {
            _profileImage = file;
          });
        }
      },
      child: CircleAvatar(
        radius: MediaQuery.of(context).size.width * 0.15,
        backgroundImage: _profileImage != null
            ? FileImage(_profileImage!)
            : const AssetImage('assets/default_profile.jpg') as ImageProvider,
        child: _profileImage == null
            ? const Icon(Icons.camera_alt, size: 40, color: Colors.grey)
            : null,
      ),
    );
  }

  Widget _registerButton() {
    return SizedBox(
      width: MediaQuery.sizeOf(context).width,
      child: MaterialButton(
        onPressed: _register,
        color: Theme.of(context).colorScheme.primary,
        child: const Text(
          "Register",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _loginAccountLink() {
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text("Already have an account? "),
          GestureDetector(
            onTap: () {
              _navigationService.goBack();
            },
            child: const Text(
              "Log in",
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
