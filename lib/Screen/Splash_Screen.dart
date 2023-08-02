import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:ume_talk/Models/keepLogIn.dart';
import 'package:page_transition/page_transition.dart';
import 'package:lottie/lottie.dart';
import '../Models/themeColor.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatelessWidget {
  final bool acceptPolicy;
  const SplashScreen({Key? key, required this.acceptPolicy}) : super(key: key);

  //late SharedPreferences prefs;


  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
      splash: Lottie.asset('images/splashScreen.json'),
      splashIconSize: 250,
      //duration: 3000,
      backgroundColor: backgroundColor,
      pageTransitionType: PageTransitionType.topToBottom,
      nextScreen: KeepLogin(acceptPolicy: acceptPolicy,),
    );
  }
}
