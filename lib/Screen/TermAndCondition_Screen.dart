import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:ume_talk/Screen/Home_Screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../Models/themeColor.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TermAndCondition extends StatefulWidget {
  final String id;
  const TermAndCondition({Key? key, required this.id }) : super(key: key);

  @override
  State<TermAndCondition> createState() => TermAndConditionState(id: id);
}

class TermAndConditionState extends State<TermAndCondition> {
  final String id;
  TermAndConditionState({Key? key, required this.id});

  bool agree = false;
  Future moveToHomePage() async{
    SharedPreferences preferences = await SharedPreferences.getInstance();
    try {
      preferences.setBool("acceptPolicy", true);
      await Future.delayed(Duration(seconds: 1));
    }catch (e){
    }
    Navigator.push(context, MaterialPageRoute(builder: (context){
      return HomeScreen(currentUserId: id);
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: themeColor,
        title: Text("Term & Condition", style: TextStyle(
          color: Colors.black
        ),),
      ),
        body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    child: Checkbox(
                      value: agree,
                      onChanged: (value) {
                        setState(() {
                          agree = value ?? false;
                        });
                      },
                    ),
                  ),
                  Text.rich(
                    TextSpan(
                      text: 'I have read and accept ',
                      children: [
                        TextSpan(
                          text: 'terms and conditions',
                          style: TextStyle(color: Colors.blue),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () async {
                              final url = 'https://dlmocha.com/app/UmeTalk-privacy';
                              if (await canLaunch(url)) {
                                await launch(url);
                              }
                            },
                        ),
                      ],
                    ),
                  ),
                ],
              ),

            TextButton(
                onPressed: agree ? moveToHomePage : null,
                child: const Text('Continue'))
          ]),
        );
  }
}
