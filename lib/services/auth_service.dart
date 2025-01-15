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
}
