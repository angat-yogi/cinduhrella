import 'package:cinduhrella/screens/home_page.dart';
import 'package:cinduhrella/screens/login_page.dart';
import 'package:cinduhrella/screens/register_page.dart';
import 'package:flutter/material.dart';

class NavigationService {
  late GlobalKey<NavigatorState> _navigatorKey;
  final Map<String, Widget Function(BuildContext)> _routes={
    "/login":(context)=>LoginPage(),
    "/register":(context)=>RegisterPage(),
    "/home":(context)=>HomePage(),
    //"/chat":(context)=>ChatPage(),
  };
  void push(MaterialPageRoute route){
    _navigatorKey.currentState?.push(route);
  }

  GlobalKey<NavigatorState> get navigatorKey{
    return this._navigatorKey;
  }
  Map<String, Widget Function(BuildContext)> get routes{
    return this._routes;
  }

  NavigationService(){
    _navigatorKey=GlobalKey<NavigatorState>();
  }

  void pushNamed(String routeName){
    _navigatorKey.currentState?.pushNamed(routeName);
  }
  void pushReplacementNamed(String routeName){
    _navigatorKey.currentState?.pushReplacementNamed(routeName);
  }
  void goBack(){
    _navigatorKey.currentState?.pop();
  }
}