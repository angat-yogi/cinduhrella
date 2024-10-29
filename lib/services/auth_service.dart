import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  User? _user;
  User? get user{
    return _user;
  }
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  AuthService(){
    _firebaseAuth.authStateChanges().listen(authStateChangesListener);  
}

Future<bool> signUp(String email, String password) async {
    try {
      // Attempt to sign in with email and password
      UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // If sign-in is successful, return true
      if( userCredential.user != null){
        _user=userCredential.user;
        return true;
      }
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase authentication errors
      if (e.code == 'user-not-found') {
        print('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        print('Wrong password provided for that user.');
      }
    } catch (e) {
      // Handle any other errors
      print(e);
    }

    // Return false if sign-in fails
    return false;
  }

  Future<bool> login(String email, String password) async {
    try {
      // Attempt to sign in with email and password
      UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // If sign-in is successful, return true
      if( userCredential.user != null){
        _user=userCredential.user;
        return true;
      }
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase authentication errors
      if (e.code == 'user-not-found') {
        print('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        print('Wrong password provided for that user.');
      }
    } catch (e) {
      // Handle any other errors
      print(e);
    }

    // Return false if sign-in fails
    return false;
  }
  void authStateChangesListener(User? user){
    _user=user;
  }

  Future<bool> logout() async{
    try{
      await _firebaseAuth.signOut();
      return true;
    }
    catch(e){
      print(e);
    }
    return false;
  }
}
