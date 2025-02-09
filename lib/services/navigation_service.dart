import 'package:cinduhrella/authentications/change_password.dart';
import 'package:cinduhrella/authentications/set_up_2fa.dart';
import 'package:cinduhrella/screens/home.dart';
import 'package:cinduhrella/screens/login_page.dart';
import 'package:cinduhrella/screens/register_page.dart';
import 'package:flutter/material.dart';

class NavigationService {
  late GlobalKey<NavigatorState> _navigatorKey;
  final Map<String, Widget Function(BuildContext)> _routes = {
    "/login": (context) => LoginPage(),
    "/register": (context) => RegisterPage(),
    "/home": (context) => HomePage(),
    '/change-password': (context) => const ChangePasswordPage(),
    '/setup-2fa': (context) => const Setup2FAPage()
    //"/chat":(context)=>ChatPage(),
  };
  void push(MaterialPageRoute route) {
    _navigatorKey.currentState?.push(route);
  }

  GlobalKey<NavigatorState> get navigatorKey {
    return _navigatorKey;
  }

  Map<String, Widget Function(BuildContext)> get routes {
    return _routes;
  }

  NavigationService() {
    _navigatorKey = GlobalKey<NavigatorState>();
  }

  /// ✅ Use `pushNamedAndReturn` for pages that need to return data
  Future<T?> pushNamedAndReturn<T>(String routeName,
      {Object? arguments}) async {
    return await _navigatorKey.currentState
        ?.pushNamed<T>(routeName, arguments: arguments);
  }

  void pushNamed(String routeName) {
    _navigatorKey.currentState?.pushNamed(routeName);
  }

  void pushReplacementNamed(String routeName) {
    _navigatorKey.currentState?.pushReplacementNamed(routeName);
  }

  void goBack() {
    _navigatorKey.currentState?.pop();
  }
}
