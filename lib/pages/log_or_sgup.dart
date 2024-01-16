import 'package:flutter/material.dart';
import 'package:smart_e/pages/signup_page.dart';

import 'login_page.dart';

class LoginAndSignUp extends StatefulWidget {
  const LoginAndSignUp({super.key});

  @override
  State<LoginAndSignUp> createState() => _LoginAndSignUpState();
}

class _LoginAndSignUpState extends State<LoginAndSignUp> {
  bool islogin = true;

  void togglePage(){
    setState(() {
      islogin = !islogin;

    });

  }
  @override
  Widget build(BuildContext context) {
    if (islogin){
      return LoginPage(
        onPressed: togglePage,
      );

    } else {
      return SignUp(
        onPressed: togglePage,
      );
    }

  }
}
