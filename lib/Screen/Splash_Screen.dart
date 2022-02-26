import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final String currentUserId;
  SplashScreen({Key? key, required this.currentUserId}) : super(key: key);

  @override
  _SplashScreenState createState() =>
      _SplashScreenState(currentUserId: currentUserId);
}

class _SplashScreenState extends State<SplashScreen> {
  final String currentUserId;
  _SplashScreenState({Key? key, required this.currentUserId});
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class Splash extends StatelessWidget {
  //const Splash({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool lightMode =
        MediaQuery.of(context).platformBrightness == Brightness.light;
    return Scaffold(
      backgroundColor: lightMode
          ? const Color(0xff55efc4).withOpacity(1.0)
          : const Color(0x00042a49).withOpacity(1.0),
      body: Center(
          child: SizedBox(
              width: 100.0,
              height: 100.0,
              child: lightMode
                  ? Image.asset('images/lottie.PNG')
                  : Image.asset('images/lottie.PNG'))),
    );
  }
}
