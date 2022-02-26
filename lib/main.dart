import 'package:flutter/material.dart';
import 'package:ume_talk/Models/keepLogIn.dart';
import 'Screen/Login_Screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:new_version/new_version.dart';
import 'dart:convert';
import 'package:internet_connection_checker/internet_connection_checker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MaterialApp(debugShowCheckedModeBanner: false, home: UmeTalk()));
}

class UmeTalk extends StatelessWidget {
  const UmeTalk({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MyApp();
  }
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool hasInternet = true;
  @override
  void initState() {
    super.initState();
    checkVersion();
    InternetConnectionChecker().onStatusChange.listen((event) {
      final hasInternet = event == InternetConnectionStatus.connected;
      setState(() {
        this.hasInternet = hasInternet;
      });
    });
  }

  void checkVersion() async {
    var url = Uri.parse('https://dlmocha.com/app/appUpdate.json');
    http.Response response = await http.get(url);
    var update = jsonDecode(response.body)['Ume Talk']['version'];
    var version = "1.0.5";
    //print(update);
    // Instantiate NewVersion manager object (Using GCP Console app as example)
    final newVersion = NewVersion(
      iOSId: 'com.leotran9x.palpitate',
      androidId: 'com.leotran9x.palpitate',
    );
    final status = await newVersion.getVersionStatus();
    if (update != version && status != null) {
      newVersion.showUpdateDialog(
        context: context,
        versionStatus: status,
        dismissButtonText: "Skip",
        dialogTitle: 'New Version Available',
        dialogText:
            'The new app version $update is available now. Please update to have a better experience.'
            '\nIf you already updated please skip.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return hasInternet
        ? FutureBuilder(
            future: Firebase.initializeApp(),
            builder: (context, snapshot) {
              // Check for errors
              if (snapshot.hasError) {
                return MaterialApp(
                  title: 'Error',
                  theme: ThemeData(
                    primaryColor: Colors.lightBlueAccent,
                  ),
                  home: Container(
                    child: Center(
                      child: Text(
                        "Error",
                        style: TextStyle(fontSize: 45, color: Colors.black),
                      ),
                    ),
                  ),
                  debugShowCheckedModeBanner: false,
                );
              }

              // Once complete, show your application
              if (snapshot.connectionState == ConnectionState.done) {
                return FirebaseAuth.instance.currentUser != null
                    ? MaterialApp(
                        title: 'Ume Talk',
                        theme: ThemeData(
                          primaryColor: Colors.lightBlueAccent,
                        ),
                        home: KeepLogin(),
                        debugShowCheckedModeBanner: false,
                      )
                    : MaterialApp(
                        title: 'Ume Talk',
                        theme: ThemeData(
                          primaryColor: Colors.lightBlueAccent,
                        ),
                        home: LoginScreen(),
                        debugShowCheckedModeBanner: false,
                      );
              }

              // Otherwise, show something whilst waiting for initialization to complete
              return MaterialApp(
                title: 'Ume Talk',
                theme: ThemeData(
                  primaryColor: Colors.lightBlueAccent,
                ),
                home: LoginScreen(),
                debugShowCheckedModeBanner: false,
              );
            },
          )
        : MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              backgroundColor: Colors.black54,
              body: Center(
                child: Text(
                  "No Internet Connection 😭",
                  style: TextStyle(
                    fontSize: 30.0,
                    color: Colors.greenAccent,
                  ),
                ),
              ),
            ),
          );
  }
}

/*
class MyApp1 extends StatelessWidget {

  void checkVersion() async {
    var url = Uri.parse('https://dlmocha.com/app/updateAPI');
    http.Response response = await http.get(url);
    var update = jsonDecode(response.body)['Ume Talk']['version'];
    var version = "1.0.0";
    //print(update);
    // Instantiate NewVersion manager object (Using GCP Console app as example)
    final newVersion = NewVersion(
      iOSId: 'com.leotran9x.palpitate',
      androidId: 'com.leotran9x.palpitate',
    );
    final status = await newVersion.getVersionStatus();
    if (update != version && status != null) {
      newVersion.showUpdateDialog(
        context: context,
        versionStatus: status,
        dismissButtonText: "Skip",
        dialogTitle: 'New Version Available',
        dialogText:
            'The new app version $update is available now. Please update to have a better experience.'
            '\nIf you already updated please skip.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Firebase.initializeApp(),
      builder: (context, snapshot) {
        // Check for errors
        if (snapshot.hasError) {
          return MaterialApp(
            title: 'Error',
            theme: ThemeData(
              primaryColor: Colors.lightBlueAccent,
            ),
            home: Container(
              child: Center(
                child: Text(
                  "Error",
                  style: TextStyle(fontSize: 45, color: Colors.black),
                ),
              ),
            ),
            debugShowCheckedModeBanner: false,
          );
        }

        // Once complete, show your application
        if (snapshot.connectionState == ConnectionState.done) {
          return FirebaseAuth.instance.currentUser != null
              ? MaterialApp(
                  title: 'Ume Talk',
                  theme: ThemeData(
                    primaryColor: Colors.lightBlueAccent,
                  ),
                  home: KeepLogin(),
                  debugShowCheckedModeBanner: false,
                )
              : MaterialApp(
                  title: 'Ume Talk',
                  theme: ThemeData(
                    primaryColor: Colors.lightBlueAccent,
                  ),
                  home: LoginScreen(),
                  debugShowCheckedModeBanner: false,
                );
        }

        // Otherwise, show something whilst waiting for initialization to complete
        return MaterialApp(
          title: 'Ume Talk',
          theme: ThemeData(
            primaryColor: Colors.lightBlueAccent,
          ),
          home: LoginScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
 */
