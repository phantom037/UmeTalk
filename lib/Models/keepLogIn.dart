import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ume_talk/Screen/Home_Screen.dart';
import 'package:ume_talk/Screen/Login_Screen.dart';

class KeepLogin extends StatefulWidget {
  @override
  _KeepLoginState createState() => _KeepLoginState();
}

class _KeepLoginState extends State<KeepLogin> {
  late User user;
  @override
  void initState() {
    super.initState();
    onRefresh(FirebaseAuth.instance.currentUser);
  }

  onRefresh(userCred) {
    // if (userCred == null) {return;}
    setState(() {
      user = userCred;
    });
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_null_comparison
    return user == null ? LoginScreen() : HomeScreen(currentUserId: user.uid);
  }
}
