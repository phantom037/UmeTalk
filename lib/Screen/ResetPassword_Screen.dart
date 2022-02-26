import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ume_talk/Models/themeColor.dart';
import 'login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ume_talk/Models/alert.dart';

class ResetPasswordScreen extends StatefulWidget {
  static String id = "Resetpasswod_Screen";
  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _auth = FirebaseAuth.instance;
  String email = "", errorMessage = "";
  bool showSpinner = false;

  @override
  Widget build(BuildContext context) {
    var textSize = MediaQuery.of(context).textScaleFactor;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: [themeColor, subThemeColor]),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: Container(),
          backgroundColor: Colors.transparent,
          elevation: 0.0,
        ),
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: Text(
                  'Reset password',
                  style: TextStyle(
                      fontSize: 30 / textSize,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic),
                ),
              ),
              SizedBox(
                height: 20.0,
              ),
              TextField(
                textAlign: TextAlign.center,
                keyboardType: TextInputType.emailAddress,
                onChanged: (value) {
                  email = value;
                },
                decoration: InputDecoration(
                  hintText: 'Enter your email',
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(32.0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueGrey, width: 1.0),
                    borderRadius: BorderRadius.all(Radius.circular(32.0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey, width: 2.0),
                    borderRadius: BorderRadius.all(Radius.circular(32.0)),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Material(
                  elevation: 5.0,
                  color: Colors.greenAccent,
                  borderRadius: BorderRadius.circular(30.0),
                  child: MaterialButton(
                    onPressed: () async {
                      setState(() {
                        showSpinner = true;
                      });
                      try {
                        final user =
                            await _auth.sendPasswordResetEmail(email: email);
                      } on FirebaseAuthException catch (error) {
                        print("Error: ${error.code}");
                        switch (error.code) {
                          case "invalid-email":
                            errorMessage = "Email is badly formatted.";
                            break;
                          case "user-not-found":
                            errorMessage = "Email does not exist in our data.";
                            break;
                          case "too-many-requests":
                            errorMessage =
                                "Too many requests. Try again later.";
                            break;
                          default:
                            errorMessage = "An undefined Error happened.";
                        }
                        setState(() {
                          showSpinner = false;
                        });
                      }
                    },
                    minWidth: 200.0,
                    height: 42.0,
                    child: Text(
                      'Send Request',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
              ),
              showAlert(errorMessage),
              MaterialButton(
                child: Text(
                  'Sign In',
                  style: TextStyle(fontSize: 14.0),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
