import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ume_talk/Models/alert.dart';
import 'package:ume_talk/Models/themeColor.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ume_talk/Screen/TermAndCondition_Screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'Home_Screen.dart';

class RegistrationScreen extends StatefulWidget {
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  bool showSpin = false, isVerified = false;
  String email = "", password = "", errorMessage = "";
  late SharedPreferences preferences;
  late User currentUser;
  Timer? timer;

  void verifyEmail(User? user) {
    if (!(user!.emailVerified)) {
      user.sendEmailVerification();
      //Fluttertoast.showToast(msg: "Check your email to verify account");
      timer = Timer.periodic(Duration(seconds: 3), (_) => checkEmailVerified(user));
      setState(() {
        errorMessage = "Check email to verify!";
      });
    }
  }

  Future checkEmailVerified(User? user) async {
    //FirebaseAuth.instance.currentUser?.reload();

    //print("Run checkEmailVerified");
    //print("verify: ${FirebaseAuth.instance.currentUser?.emailVerified}");
    setState(() {
      user!.reload();
      isVerified = FirebaseAuth.instance.currentUser?.emailVerified ?? false; //user!.emailVerified;
    });
    print("isVerified: $isVerified"); //user!.emailVerified
    if (isVerified) {
      timer?.cancel();
      checkLoginInStatus(user);
    }
  }

  Future checkLoginInStatus(User? user) async {
    preferences = await SharedPreferences.getInstance();

    
    ///Non Use Check if user has verify account
    if (user != null && !user.emailVerified) {
      //await user.sendEmailVerification();
      Fluttertoast.showToast(msg: "Check your email to verify account");
    }

    ///Check if Register Success
    if (user != null) {
      final QuerySnapshot resultQuery = await FirebaseFirestore.instance
          .collection("user")
          .where("id", isEqualTo: user.uid)
          .get();
      final List<DocumentSnapshot> documentSnapshots = resultQuery.docs;

      ///New User write data to Firebase
      if (documentSnapshots.length == 0) {
        String convert =
            user.displayName.toString().toLowerCase().replaceAll(' ', '');
        var arraySearchID = List.filled(convert.length, "");
        if (user.displayName != null) {
          for (int i = 0; i < convert.length; i++) {
            arraySearchID[i] =
                convert.substring(0, i + 1).toString().toLowerCase();
          }
        } else {
          String newUnknownUserName = "user" + user.uid.substring(0, 9);
          arraySearchID = new List.filled(newUnknownUserName.length, "");
          for (int i = 0; i < newUnknownUserName.length; i++) {
            arraySearchID[i] =
                newUnknownUserName.substring(0, i + 1).toString().toLowerCase();
          }
        }
        FirebaseFirestore.instance.collection("user").doc(user.uid).set({
          "name": user.displayName != null
              ? user.displayName
              : "User " + user.uid.substring(0, 9),
          "photoUrl": user.photoURL != null
              ? user.photoURL
              : "https://dlmocha.com/app/Ume-Talk/userDefaultAvatar.jpeg",
          "id": user.uid,
          "about": "None",
          "createdAt": DateTime.now().toString(),
          "chatWith": null,
          "searchID": arraySearchID,
          "updateNewChatList": false,
          "token": "No-data",
        });
        //Write data to Local
        currentUser = user;

        await preferences.setString("id", currentUser.uid);
        await preferences.setString("name", currentUser.displayName.toString());
        await preferences.setString(
            "photoUrl",
            currentUser.photoURL.toString() != null
                ? currentUser.photoURL.toString()
                : "https://dlmocha.com/app/Ume-Talk/userDefaultAvatar.jpeg");
        await preferences.setString("about", "None");

        Fluttertoast.showToast(msg: "Register Success");
        await Future.delayed(Duration(seconds: 3));
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return TermAndCondition(id: preferences.getString("id").toString()); //HomeScreen(currentUserId: preferences.getString("id").toString());
        }));
      }
      setState(() {
        showSpin = false;
      });
    } else {
      ///SignIn fail
      Fluttertoast.showToast(msg: "Fail to Register. Please try again.");
      setState(() {
        showSpin = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var textSize = MediaQuery.of(context).textScaleFactor;
    return Container(
      color: backgroundColor,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back_ios_new),
            color: Colors.black,
            splashRadius: 0.1, // Set a small value to disable the ripple effect
            highlightColor: Colors.transparent, // Disable the highlight color
            hoverColor: Colors.transparent, // Disable the hover color
          ),
          backgroundColor: Colors.transparent,
          elevation: 0.0,
        ),

          body: Stack(
            children: <Widget>[
              Positioned.fill(
                child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Center(
                    child: Text(
                      "Create yours",
                      style: TextStyle(
                          fontSize: 30.0 / textSize,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic),
                    ),
                  ),
                  const SizedBox(
                    height: 48.0,
                  ),
                  TextField(
                    keyboardType: TextInputType.emailAddress,
                    textAlign: TextAlign.start,
                    onChanged: (value) {
                      email = value;
                    },
                    decoration: const InputDecoration(
                      hintText: 'Email',
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
                  const SizedBox(
                    height: 10.0,
                  ),
                  TextField(
                    obscureText: true,
                    textAlign: TextAlign.start,
                    onChanged: (value) {
                      password = value;
                    },
                    decoration: const InputDecoration(
                      hintText: 'Password',
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
                  const SizedBox(
                    height: 24.0,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Material(
                      borderRadius: const BorderRadius.all(Radius.circular(19.0)),
                      elevation: 5.0,
                      child: Ink(
                        decoration: BoxDecoration(
                          color: buttonColor,
                          borderRadius: BorderRadius.circular(19.0),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(19.0),
                          onTap: () async {
                            setState(() {
                              showSpin = true;
                            });
                            try {
                              User? newUser = (await firebaseAuth.createUserWithEmailAndPassword(
                                  email: email, password: password)).user;
                              if (newUser != null) {
                                verifyEmail(newUser);
                              }
                              setState(() {
                                showSpin = false;
                              });
                            } on FirebaseAuthException catch (error) {
                              switch (error.code) {
                                case "invalid-email":
                                  errorMessage = "Email is badly formatted.";
                                  break;
                                case "weak-password":
                                  errorMessage = "Password requires at least 6 letters.";
                                  break;
                                case "email-already-in-use":
                                  errorMessage = "This email has already been used.";
                                  break;
                                case "too-many-requests":
                                  errorMessage = "Too many requests. Try again later.";
                                  break;
                                default:
                                  errorMessage = "An undefined Error happened.";
                              }
                              setState(() {
                                Fluttertoast.showToast(msg: "Fail to register. Please try again.");
                                showSpin = false;
                              });
                            }
                          },
                          child: Container(
                            width: 200.0,
                            height: 50.0,
                            alignment: Alignment.center,
                            child: const Text(
                              'Register',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 18.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 15.0,
                  ),
                  showAlert(errorMessage),

                  ///Todo add circular progress process registration
                  /*
                  Padding(
                    padding: EdgeInsets.all(1.0),
                    child: showSpin ? circularProgress() : Container(),
                  ),

                   */
                ],
            ),
        ),
              ),
              Positioned(
                  left: 0,
                  right: 0,
                  bottom: 20,
                  child: Container(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Text("By continue you agree with", style: TextStyle(fontSize: 12, color: Colors.black45),),
                    const SizedBox(
                      width: 3,
                    ),
                    Container(
                      alignment: Alignment.topLeft,
                      child: GestureDetector(
                          child: const Text(
                            "terms & condition",
                            style: TextStyle(
                              color: Colors.black45,
                              fontSize: 12.0,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          onTap: () {
                            launch("https://dlmocha.com/app/UmeTalk-privacy");
                          }),
                    ),
                  ],),
              ))
          ]),
      ),
    );
  }
}
