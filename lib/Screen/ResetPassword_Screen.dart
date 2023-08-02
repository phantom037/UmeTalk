import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ume_talk/Models/themeColor.dart';
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
      color: backgroundColor,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: Container(),
          backgroundColor: Colors.transparent,
          elevation: 0.0,
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
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
              const SizedBox(
                height: 20.0,
              ),
              TextField(
                textAlign: TextAlign.center,
                keyboardType: TextInputType.emailAddress,
                onChanged: (value) {
                  email = value;
                },
                decoration: const InputDecoration(
                  hintText: 'Enter your email',
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 10.0, horizontal: 20.0),
                  border: const OutlineInputBorder(
                    borderRadius: const BorderRadius.all(Radius.circular(19.0)),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderSide:
                        const BorderSide(color: Colors.black38, width: 1.0),
                    borderRadius: const BorderRadius.all(Radius.circular(19.0)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide:
                        const BorderSide(color: Colors.black45, width: 2.0),
                    borderRadius: const BorderRadius.all(Radius.circular(19.0)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Material(
                  elevation: 5.0,
                  color: buttonColor,
                  borderRadius: BorderRadius.circular(19.0),
                  child: MaterialButton(
                    shape: RoundedRectangleBorder(borderRadius:BorderRadius.circular(19.0)),
                    onPressed: () async {
                      setState(() {
                        showSpinner = true;
                      });
                      try {
                        final user =
                            await _auth.sendPasswordResetEmail(email: email);
                        setState(() {
                          errorMessage = "Check your email to reset password.";
                        });
                      } on FirebaseAuthException catch (error) {
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
                    child: const Text(
                      'Send Request',
                      style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 18.0),
                    ),
                  ),
                ),
              ),
              showAlert(errorMessage),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 120),
                child: Container(
                  alignment: Alignment.center,
                  child: GestureDetector(
                      child: const Text(
                        "Back to sign in",
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 15.0,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                      }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
