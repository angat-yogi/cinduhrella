import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logger/logger.dart';

class AuthService {
  User? _user = FirebaseAuth.instance.currentUser;
  User? get user {
    return _user;
  }

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final Logger _logger = Logger(); // Initialize the logger
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; // Initialize Firestore

  AuthService() {
    _firebaseAuth.authStateChanges().listen(authStateChangesListener);
  }

  Future<bool> signUp(String email, String password) async {
    try {
      // Attempt to sign in with email and password
      UserCredential userCredential =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // If sign-in is successful, return true
      if (userCredential.user != null) {
        _user = userCredential.user;
        return true;
      }
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase authentication errors
      if (e.code == 'user-not-found') {
        _logger.e('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        _logger.e('Wrong password provided for that user.');
      }
    } catch (e) {
      // Handle any other errors
      _logger.e(e);
    }

    // Return false if sign-in fails
    return false;
  }

  Future<User?> signInWithGoogle() async {
    // Trigger the Google authentication flow
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    // If the user cancels the sign-in flow, return null
    if (googleUser == null) return null;

    // Obtain the auth details from the request
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    // Create a new credential
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Once signed in, return the UserCredential
    return (await FirebaseAuth.instance.signInWithCredential(credential)).user;
  }

  Future<bool> login(String email, String password) async {
    try {
      // Attempt to sign in with email and password
      UserCredential userCredential =
          await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // If sign-in is successful, return true
      if (userCredential.user != null) {
        _user = userCredential.user;
        return true;
      }
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase authentication errors
      if (e.code == 'user-not-found') {
        _logger.e('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        _logger.e('Wrong password provided for that user.');
      }
    } catch (e) {
      // Handle any other errors
      _logger.e(e);
    }

    // Return false if sign-in fails
    return false;
  }

  void authStateChangesListener(User? user) {
    _user = user;
  }

  Future<bool> logout() async {
    try {
      await _firebaseAuth.signOut();
      return true;
    } catch (e) {
      _logger.e(e);
    }
    return false;
  }

  Future<bool> changePassword(String newPassword) async {
    try {
      await _firebaseAuth.currentUser!.updatePassword(newPassword);
      return true;
    } catch (e) {
      print("Error changing password: $e");
      return false;
    }
  }

  Future<bool> is2FAEnabled() async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user!.uid).get();
      return userDoc.exists && (userDoc['is2FAEnabled'] ?? false);
    } catch (e) {
      print("Error checking 2FA: $e");
      return false;
    }
  }

  /// **Get the current 2FA option (Email or Phone)**
  Future<String> get2FAOption() async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user!.uid).get();
      return userDoc.exists && userDoc['2FAOption'] != null
          ? userDoc['2FAOption']
          : "email"; // Default to email
    } catch (e) {
      print("Error getting 2FA option: $e");
      return "email"; // Default fallback
    }
  }

  /// **Enable or Disable 2FA with a selected option**
  Future<bool> set2FA(bool enable, String option) async {
    try {
      await _firestore.collection('users').doc(user!.uid).set(
        {'is2FAEnabled': enable, '2FAOption': option},
        SetOptions(merge: true),
      );

      // ✅ Verify Firestore update
      bool updatedStatus = await is2FAEnabled();
      String updatedOption = await get2FAOption();
      return updatedStatus == enable && updatedOption == option;
    } catch (e) {
      print("Error updating 2FA status: $e");
      return false;
    }
  }

  Future<bool> reAuthenticateAndChangePassword(
      String email, String oldPassword, String newPassword) async {
    try {
      AuthCredential credential =
          EmailAuthProvider.credential(email: email, password: oldPassword);
      await _firebaseAuth.currentUser!.reauthenticateWithCredential(credential);
      await _firebaseAuth.currentUser!.updatePassword(newPassword);
      return true;
    } catch (e) {
      print("Re-authentication failed: $e");
      return false;
    }
  }

  Future<String?> getEmail() async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user!.uid).get();
      return userDoc.exists ? userDoc['email'] : null;
    } catch (e) {
      print("Error fetching email: $e");
      return null;
    }
  }

  Future<String?> getCountryCode() async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user!.uid).get();
      return userDoc.exists
          ? userDoc['countryCode']
          : "+1"; // Default to +1 if missing
    } catch (e) {
      print("Error fetching country code: $e");
      return "+1";
    }
  }

  /// **Verify and Set Email for 2FA**
  Future<bool> verifyAndSetEmail(String email) async {
    try {
      // Send verification email
      await _firebaseAuth.currentUser!.verifyBeforeUpdateEmail(email);
      print("Verification email sent to: $email");

      // Wait for user to verify email manually in inbox
      await Future.delayed(const Duration(seconds: 5)); // Simulate waiting

      // Check if email is now verified
      await _firebaseAuth.currentUser!.reload();
      if (!_firebaseAuth.currentUser!.emailVerified) {
        print("Email not verified yet.");
        return false;
      }

      // Store the verified email in Firestore
      await _firestore.collection('users').doc(user!.uid).set(
        {'email': email},
        SetOptions(merge: true),
      );

      print("Email updated successfully in Firestore.");
      return true;
    } catch (e) {
      print("Error verifying and setting email: $e");
      return false;
    }
  }

  String? _verificationId;

  /// **Get the current phone number from Firestore**
  Future<String?> getPhoneNumber() async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user!.uid).get();
      return userDoc.exists ? userDoc['phoneNumber'] : null;
    } catch (e) {
      print("Error fetching phone number: $e");
      return null;
    }
  }

  /// **Step 1: Send OTP to the phone number**
  Future<bool> sendOTP(String phoneNumber) async {
    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          print("Auto-verification completed");
        },
        verificationFailed: (FirebaseAuthException e) {
          print("Verification failed: ${e.message}");
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId; // ✅ Store verificationId correctly
          print("OTP sent. Verification ID: $_verificationId");
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId =
              verificationId; // ✅ Ensure it's stored before timeout
        },
      );
      return true;
    } catch (e) {
      print("Error sending OTP: $e");
      return false;
    }
  }

  /// **Step 1: Send OTP to disable 2FA**
  Future<bool> sendOTPToDisable2FA(String phoneNumber) async {
    try {
      print("Sending OTP to: $phoneNumber");

      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _firebaseAuth.currentUser
              ?.reauthenticateWithCredential(credential);
          _verificationId = credential.verificationId;
          print(
              "Auto-verification completed. Verification ID: $_verificationId");
        },
        verificationFailed: (FirebaseAuthException e) {
          print("OTP Sending Failed: ${e.message}");
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          print("OTP sent. Verification ID: $_verificationId");
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
          print(
              "Auto retrieval timeout. Verification ID stored: $_verificationId");
        },
      );

      return _verificationId != null;
    } catch (e) {
      print("Error sending OTP to disable 2FA: $e");
      return false;
    }
  }

  /// **Step 2: Verify OTP to disable 2FA**
  Future<bool> verifyOTPToDisable2FA(String otp) async {
    try {
      if (_verificationId == null) {
        print("Error: Verification ID is null. Cannot verify OTP.");
        return false;
      }

      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      // Reauthenticate user before removing phone number
      await _firebaseAuth.currentUser?.reauthenticateWithCredential(credential);

      // ✅ Remove phone number from Firebase Auth
      // Remove phone number from Firestore (if stored there)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_firebaseAuth.currentUser?.uid)
          .update({'phoneNumber': FieldValue.delete()});

      return true;
    } catch (e) {
      print("Error verifying OTP to disable 2FA: $e");
      return false;
    }
  }

  /// **Step 2: Verify OTP and set phone number**
  Future<bool> verifyAndSetPhoneNumber(String otp, String phoneNumber) async {
    try {
      if (_verificationId == null) {
        print("No verification ID found.");
        return false;
      }

      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      await user!.updatePhoneNumber(credential);
      await _savePhoneNumber(phoneNumber);

      print("Phone number verified and updated successfully.");
      return true;
    } catch (e) {
      print("Error verifying phone number: $e");
      return false;
    }
  }

  /// **Save verified phone number to Firestore**
  Future<void> _savePhoneNumber(String phoneNumber) async {
    await _firestore.collection('users').doc(user!.uid).set(
      {'phoneNumber': phoneNumber},
      SetOptions(merge: true),
    );
  }
}
