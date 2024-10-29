import 'package:cinduhrella/const.dart';
import 'package:cinduhrella/services/alert_service.dart';
import 'package:cinduhrella/services/auth_service.dart';
import 'package:cinduhrella/services/navigation_service.dart';
import 'package:cinduhrella/widgets/custom_form_field.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
class LoginPage extends StatefulWidget {
  
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
   
   String? email;
   String? password;
   final GetIt _getIt = GetIt.instance;
   late AuthService _authService;
    late NavigationService _navigationService;
    late AlertService _alertService;
  final GlobalKey<FormState> _loginFormKey= GlobalKey();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _authService=_getIt.get<AuthService>();
    _navigationService=_getIt.get<NavigationService>();
    _alertService=_getIt.get<AlertService>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body:_buildUI());
  }
  
  Widget _buildUI() {
  return SafeArea(
    child: Padding(
    padding:const EdgeInsets.symmetric(
    horizontal: 15.0,
    vertical: 20.0,
      ),
      child: Column(children: [
      _headerText(),
      _loginForm(),
      _createAnAccountLink()
      ],
      ),
    )
  );
}

  Widget _headerText(){
    return SizedBox(
      width: MediaQuery.sizeOf(context).width,
      child: const Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            "Hi, Welcome Back!",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
           Text(
            "Hello Again, you've been missed!",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.grey
            ),
          )
        ],
      ),
    );
  }
  Widget _loginForm(){
    return Container(
      height: MediaQuery.sizeOf(context).height*0.5,
      margin: EdgeInsets.symmetric(
        vertical: MediaQuery.sizeOf(context).height*0.06
      ), 
      child: Form(
        key:_loginFormKey,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CustomFormField(
              onSaved: (value){
                setState(() {
                  email=value;
                });
              },
              obscureText: false,
              validationRegExp: EMAIL_PATTERN,
              hintPlaceHolder: "Email", 
              height: MediaQuery.sizeOf(context).height*0.1,
            ),
            CustomFormField(
              onSaved: (value){
                setState(() {
                  password=value;
                });
              },
              obscureText: true,
              validationRegExp: PASSWORD_PATTERN,
              hintPlaceHolder: "Password",
              height: MediaQuery.sizeOf(context).height*0.1,
            ),
            _loginButton()
          ],
        ),
      ),
    );
  }

  Widget _loginButton(){

    return SizedBox(width:MediaQuery.sizeOf(context).width,
    child: MaterialButton(onPressed: () async {
      if(_loginFormKey.currentState?.validate()??false){
        _loginFormKey.currentState?.save();
      
        bool loginResult= await _authService.login(email!, password!);
        if(loginResult){
          _navigationService.pushReplacementNamed("/home");
          _alertService.showToast(text: "Welcome Back!", icon: Icons.check_circle);
        }else{
          _alertService.showToast(text: "Failed to login, please try again!", icon: Icons.error);
        }
      }
    },
    color: Theme.of(context).colorScheme.primary,
    child: const Text(
      "Login",
      style: TextStyle(
        color:Colors.white
      )
    ),
    ),
    );
  }

  Widget _createAnAccountLink(){
    return  Expanded(child:Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
     children: [ 
       const Text("New to ProfSphere? "),
       GestureDetector(
        onTap: (){
          _navigationService.pushNamed("/register");
        },
         child: const Text("Sign Up",
               style: TextStyle(
          fontWeight: FontWeight.w800,
               )
               ),
       )
     ],

    ));
  }
}