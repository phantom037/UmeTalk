import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ume_talk/Models/alert.dart';
import 'package:ume_talk/Screen/Home_Screen.dart';
import 'package:ume_talk/Screen/Registration_Screen.dart';
import 'package:ume_talk/Screen/ResetPassword_Screen.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ume_talk/Models/themeColor.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Widgets/Progress_Widget.dart';

class LoginScreen extends StatefulWidget {
  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  GoogleSignIn _googleSignIn = GoogleSignIn();
  FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  late SharedPreferences preferences;
  late User currentUser;
  bool isLoggedIn = false;
  bool showSpin = false;
  String email = "", password = "", errorMessage = "";
  final FocusNode emailFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
  }

  void isSignedIn() async {
    this.setState(() {
      isLoggedIn = true;
    });

    preferences = await SharedPreferences.getInstance();
    isLoggedIn = await _googleSignIn.isSignedIn();
    if (isLoggedIn) {
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return HomeScreen(
            currentUserId: preferences.getString("id").toString());
      }));
    }
    showSpin = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Container(
            color: backgroundColor,
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Center(
                    child: showSpin
                        ? Padding(
                            padding: EdgeInsets.all(1.0),
                            child: circularProgress(),
                          )
                        : Image.asset(
                            "images/logo.png",
                            width: 120,
                            height: 40,
                          )),
                const SizedBox(
                  height: 10.0,
                ),
                TextField(
                  textAlign: TextAlign.start,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (value) {
                    email = value;
                  },
                  focusNode: emailFocusNode,
                  decoration: const InputDecoration(
                    hintText: "Email",
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
                  textAlign: TextAlign.start,
                  obscureText: true,
                  onChanged: (value) {
                    password = value;
                  },
                  focusNode: passwordFocusNode,
                  decoration: const InputDecoration(
                    hintText: "Password",
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 10.0, horizontal: 20.0),
                    border: const OutlineInputBorder(
                      borderRadius: const BorderRadius.all(Radius.circular(32.0)),
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
                Container(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                      child: const Text(
                        "Forgot password",
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 15.0,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      onTap: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) {
                          return ResetPasswordScreen();
                        }));
                      }),
                ),
                Center(child: showAlert(errorMessage)),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
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
                        onTap: normalControlSignIn,
                        child: Container(
                          width: 200.0,
                          height: 50.0,
                          alignment: Alignment.center,
                          child: const Text(
                            'Sign In',
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
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
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
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) {
                            return RegistrationScreen();
                          }));
                        },
                        child: Container(
                          width: 200.0,
                          height: 50.0,
                          alignment: Alignment.center,
                          child: const Text(
                            'Create',
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


                /*
                ///Todo : Uncomment method below for android devices

                GestureDetector(
                  child: Center(
                    child: Container(
                      width: 270.0,
                      height: 65.0,
                      decoration: BoxDecoration(
                          image: DecorationImage(
                              image:
                                  AssetImage('images/google_signin_button.png'))),
                    ),
                  ),
                  onTap: googleControlSignIn,
                ),
                */


                ///Todo : Uncomment method below for iOS devices
                const SizedBox(
                  height: 15.0,
                ),
                const Center(
                  child: const Text(
                    "Continue with",
                    style: const TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic),
                  ),
                ),
                SizedBox(height: 15.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    GestureDetector(
                      child: Center(
                        child: Container(
                          width: 50.0,
                          height: 50.0,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.all(Radius.circular(5.0)),
                              color: Colors.white,
                              image: DecorationImage(
                                  image: AssetImage('images/google.png'))),
                        ),
                      ),
                      onTap: googleControlSignIn,
                    ),
                    const SizedBox(
                      width: 30,
                    ),
                    GestureDetector(
                      child: Center(
                        child: Container(
                          width: 50.0,
                          height: 50.0,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.all(Radius.circular(5.0)),
                              color: Colors.black,
                              image: DecorationImage(
                                image: AssetImage('images/apple.png'),
                              )),
                        ),
                      ),
                      onTap: appleControlSignIn,
                    ),
                  ],
                ),
                const SizedBox(
                  height: 20.0,
                ),


                ///Todo add circular progress process login
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
    );
  }

  Future googleControlSignIn() async {
    preferences = await SharedPreferences.getInstance();

    GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    GoogleSignInAuthentication googleSignInAuthentication =
        await googleUser!.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      idToken: googleSignInAuthentication.idToken,
      accessToken: googleSignInAuthentication.accessToken,
    );
    User? user = (await firebaseAuth.signInWithCredential(credential)).user;

    checkLoginInStatus(user);
  }

  String generateNonce([int length = 32]) {
    final charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  /// Returns the sha256 hash of [input] in hex notation.
  String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future appleControlSignIn() async {
    try {
      final rawNonce = generateNonce();
      final nonce = sha256ofString(rawNonce);
      print("rawNonce: $rawNonce");
      print("nonce: $nonce");
      preferences = await SharedPreferences.getInstance();
      var result = await SignInWithApple.getAppleIDCredential(scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ], nonce: nonce);

      final appleCredential = OAuthProvider("apple.com").credential(
          accessToken: result.identityToken,
          rawNonce: rawNonce,
          idToken: result.identityToken);

      final authResult =
          await firebaseAuth.signInWithCredential(appleCredential);
      User? user = authResult.user;

      checkLoginInStatus(user);
    } on Error catch (e) {
      Fluttertoast.showToast(
          toastLength: Toast.LENGTH_LONG,
          msg: "Apple sign in request IOS 14+");
    }
  }

  //Check if user verify account and catch other errors
  Future normalControlSignIn() async {
    preferences = await SharedPreferences.getInstance();
    setState(() {
      showSpin = true;
    });
    try {
      User? user = (await firebaseAuth.signInWithEmailAndPassword(
              email: email, password: password))
          .user;

      if (user != null && user.emailVerified) {
        checkLoginInStatus(user);
        setState(() {
          showSpin = false;
          emailFocusNode.unfocus();
          passwordFocusNode.unfocus();
        });
      } else {
        user!.sendEmailVerification();
        Fluttertoast.showToast(msg: "Check your email to verify account");
        setState(() {
          showSpin = false;
        });
      }
    } on FirebaseAuthException catch (error) {
      switch (error.code) {
        case "invalid-email":
          errorMessage = "Email is badly formatted.";
          break;
        case "wrong-password":
          errorMessage = "Password is incorrect.";
          break;
        case "user-not-found":
          errorMessage = "User with this email doesn't exist.";
          break;
        case "user-disabled":
          errorMessage = "Your account has been disabled.";
          break;
        case "too-many-requests":
          errorMessage = "Too many requests. Try again later.";
          break;
        default:
          errorMessage = "An undefined Error happened.";
      }
      setState(() {
        showSpin = false;
      });
    }
  }

  Future checkLoginInStatus(User? user) async {
    setState(() {
      showSpin = true;
    });

    /*
    ///Check if user has verify account
    if (user != null && !user.emailVerified) {
      Fluttertoast.showToast(msg: "Check your email to verify account");
      await user.sendEmailVerification();
    }
     */

    ///Check if Login Success
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
          "name": (user.displayName != null || user.displayName == "null")
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
        //currentUser.displayName == null ? displayName = "" : displayName = currentUser.displayName.toString();
        await preferences.setString("id", currentUser.uid);
        await preferences.setString("name", currentUser.displayName.toString());
        await preferences.setString(
            "photoUrl", currentUser.photoURL.toString());
        await preferences.setString("about", "None");
        Fluttertoast.showToast(msg: "Loading");
        Future.delayed(Duration(seconds: 3), () {
          Navigator.push(context, MaterialPageRoute(builder: (context) {
            return HomeScreen(
                currentUserId: preferences.getString("id").toString());
          }));
        });
      } else {
        ///Check if already SignedUp User
        //Write data to Local
        currentUser = user;
        await preferences.setString("id", documentSnapshots[0]["id"]);
        await preferences.setString(
            "name",
            documentSnapshots[0]["name"] != null
                ? documentSnapshots[0]["name"]
                : "Unknown User");
        await preferences.setString(
            "photoUrl",
            documentSnapshots[0]["photoUrl"] != null
                ? documentSnapshots[0]["photoUrl"]
                : "https://dlmocha.com/app/Ume-Talk/userDefaultAvatar.jpeg");
        await preferences.setString("about", documentSnapshots[0]["about"]);
        Fluttertoast.showToast(msg: "Loading");
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return HomeScreen(
              currentUserId: preferences.getString("id").toString());
        }));
      }
      setState(() {
        showSpin = false;
      });
    } else {
      ///SignIn fail
      Fluttertoast.showToast(
          toastLength: Toast.LENGTH_LONG,
          msg: "Fail to sign in. Please try again.");
      setState(() {
        showSpin = false;
      });
    }
  }
}
