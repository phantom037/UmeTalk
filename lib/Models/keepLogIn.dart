import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ume_talk/Screen/Home_Screen.dart';
import 'package:ume_talk/Screen/Login_Screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ume_talk/Screen/TermAndCondition_Screen.dart';


class KeepLogin extends StatefulWidget {
  final bool acceptPolicy;
  const KeepLogin({Key? key, required this.acceptPolicy});
  @override
  _KeepLoginState createState() => _KeepLoginState(acceptPolicy: acceptPolicy);
}

class _KeepLoginState extends State<KeepLogin> {
  final bool acceptPolicy;
  _KeepLoginState({Key? key, required this.acceptPolicy});
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
    return user == null ? LoginScreen() : acceptPolicy ? HomeScreen(currentUserId: user.uid) : TermAndCondition(id: user.uid);
  }
}
