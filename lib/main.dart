import 'package:cinduhrella/auth_gate.dart';
import 'package:cinduhrella/firebase_options.dart';
import 'package:cinduhrella/screens/navigator.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const AuthGate(), // Authentication handling
        '/main': (context) =>
            NavigatorScreen(), // Main app screen with bottom navigation
      },
    );
  }
}
