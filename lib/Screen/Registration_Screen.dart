import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ume_talk/Models/alert.dart';
import 'package:ume_talk/Models/themeColor.dart';
import 'package:ume_talk/Widgets/Progress_Widget.dart';
import 'Home_Screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';

class RegistrationScreen extends StatefulWidget {
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  bool showSpin = false;
  String email = "", password = "", errorMessage = "";
  late SharedPreferences preferences;
  late User currentUser;

  Future checkLoginInStatus(User? user) async {
    preferences = await SharedPreferences.getInstance();

    ///Check if user has verify account
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
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
              : "https://applywave.com/wp-content/uploads/2020/01/DeAnza.png",
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
        //Fluttertoast.showToast(msg: "Register Success");
        await Future.delayed(Duration(seconds: 3));
        /*
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return
            HomeScreen(currentUserId: preferences.getString("id").toString());
        }));
         */
        Navigator.pop(context);
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.bottomRight,
            end: Alignment.topLeft,
            colors: [themeColor, subThemeColor]),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: null,
          backgroundColor: Colors.transparent,
          elevation: 0.0,
        ),
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              /*
                Flexible(
                  child: Hero(
                    tag: 'logo',
                    child: Container(
                      height: 200.0,
                      child: Image.asset('images/logo.png'),
                    ),
                  ),
                ), //Flexible

                 */
              Center(
                child: Text(
                  "Create yours",
                  style: TextStyle(
                      fontSize: 30.0 / textSize,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic),
                ),
              ),
              SizedBox(
                height: 48.0,
              ),
              TextField(
                keyboardType: TextInputType.emailAddress,
                textAlign: TextAlign.center,
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
              SizedBox(
                height: 8.0,
              ),
              TextField(
                obscureText: true,
                textAlign: TextAlign.center,
                onChanged: (value) {
                  password = value;
                },
                decoration: InputDecoration(
                  hintText: 'Enter your password',
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
              SizedBox(
                height: 24.0,
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Material(
                  color: Colors.greenAccent,
                  borderRadius: BorderRadius.all(Radius.circular(30.0)),
                  elevation: 5.0,
                  child: MaterialButton(
                    onPressed: () async {
                      setState(() {
                        showSpin = true;
                      });
                      try {
                        User? newUser =
                            (await firebaseAuth.createUserWithEmailAndPassword(
                                    email: email, password: password))
                                .user;
                        if (newUser != null) {
                          checkLoginInStatus(newUser);
                        }
                        setState(() {
                          showSpin = false;
                        });
                      } on FirebaseAuthException catch (error) {
                        print("Error: ${error.code}");
                        switch (error.code) {
                          case "invalid-email":
                            errorMessage = "Email is badly formatted.";
                            break;
                          case "weak-password":
                            errorMessage =
                                "Password requires at least 6 letters.";
                            break;
                          case "email-already-in-use":
                            errorMessage = "This email has already used.";
                            break;
                          case "too-many-requests":
                            errorMessage =
                                "Too many requests. Try again later.";
                            break;
                          default:
                            errorMessage = "An undefined Error happened.";
                        }
                        setState(() {
                          Fluttertoast.showToast(
                              msg: "Fail to register. Please try again.");
                          showSpin = false;
                        });
                      }
                    },
                    minWidth: 200.0,
                    height: 42.0,
                    child: Text(
                      'Register',
                      style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 18.0),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 15.0,
              ),
              showAlert(errorMessage),
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
    );
  }
}
