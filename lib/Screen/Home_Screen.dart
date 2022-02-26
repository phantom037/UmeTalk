import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'package:ume_talk/Models/screenTransition.dart';
import 'package:ume_talk/Models/themeColor.dart';
import 'package:ume_talk/Screen/Chat_Screen.dart';
import 'package:ume_talk/Models/user.dart';
import 'package:ume_talk/Screen/Setting_Screen.dart';
import 'package:ume_talk/Widgets/ChatWithProfile_Widget.dart';
import 'package:ume_talk/Widgets/Progress_Widget.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
//import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:new_version/new_version.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ume_talk/Models/notification.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';

class HomeScreen extends StatefulWidget {
  final String currentUserId;
  HomeScreen({Key? key, required this.currentUserId}) : super(key: key);
  @override
  State createState() => HomeScreenState(currentUserId: currentUserId);
}

class HomeScreenState extends State<HomeScreen> {
  HomeScreenState({Key? key, required this.currentUserId});

  final GoogleSignIn googleSignIn = GoogleSignIn();
  TextEditingController searchTextEditingController = TextEditingController();
  final String currentUserId;
  String searchName = "";
  late bool hasAlreadyChatWithSomeone = false;
  List<ProfileChatWith> chatWithList = [];

  final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    // TODO: implement initState
    FlutterAppBadger.removeBadge();
    super.initState();
    checkChatList();
    checkVersion();
    ErrorWidget.builder = (FlutterErrorDetails details) => Container();
    //NotificationAPI.init();
    registerNotification();
    configureLocalNotification();
  }

  /*
  void listenNotifications() =>
      NotificationAPI.onNotification.stream.listen(onClickedNotification);

  void onClickedNotification(String? payload) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (context) {
        return SettingsScreen();
      }));

   */

  ///Add async
  void registerNotification() async {
    //print("firebaseMessaging");
    await firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        //Show notification
        showNotification(message.notification!);
      }
      return;
    });

    firebaseMessaging.getToken().then((token) {
      if (token != null) {
        FirebaseFirestore.instance
            .collection("user")
            .doc(currentUserId)
            .update({
          "token": token,
        }).catchError((error) {
          Fluttertoast.showToast(
              msg: "Error from firebaseMessaging" + error.toString());
        });
      }
    });
  }

  void configureLocalNotification() {
    final iosSetting = IOSInitializationSettings();
    final androidSetting = AndroidInitializationSettings('app_icon');
    final settings =
        InitializationSettings(android: androidSetting, iOS: iosSetting);
    flutterLocalNotificationsPlugin.initialize(settings);
  }

  void showNotification(RemoteNotification remoteNotification) async {
    FlutterAppBadger.updateBadgeCount(1);
    AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails('com.leotran9x.ume_talk', 'Ume Talk',
            playSound: true,
            enableVibration: true,
            importance: Importance.max,
            channelShowBadge: true,
            icon: '@mipmap/app_icon'

            //styleInformation: styleInformation,
            //fullScreenIntent: true
            );
    IOSNotificationDetails iosNotificationDetails = IOSNotificationDetails();
    NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails, iOS: iosNotificationDetails);

    await flutterLocalNotificationsPlugin.show(
      0,
      remoteNotification.title,
      remoteNotification.body,
      notificationDetails,
      payload: null,
    );
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

  void checkChatList() async {
    var snapshot = await FirebaseFirestore.instance
        .collection("user")
        .doc(currentUserId)
        .get();
    //print("ID chat with : ${snapshot["chatWith"]}");

    ///Fix from here
    var idChatWith = [];
    if (snapshot["chatWith"] != null) {
      setState(() {
        hasAlreadyChatWithSomeone = true;
      });
    }

    ///End Fix
    //print("Has chatted with $hasAlreadyChatWithSomeone");
  }

  ///Unused
  List arrangeChattedList(var database) {
    List<String> chattedList = [];
    for (var item in database) {
      chattedList.insert(0, item);
    }

    final Stream<List<ProfileChatWith>> chatStream =
        Stream<List<ProfileChatWith>>.fromIterable(<List<ProfileChatWith>>[
      List<ProfileChatWith>.generate(
          10,
          (int i) => ProfileChatWith(
              userId: database[i], currentUserId: currentUserId))
    ]);

    return chattedList;
  }

  Header() {
    return AppBar(
      backgroundColor: themeColor,
      title: Container(
        margin: new EdgeInsets.only(bottom: 4.0),
        child: TextFormField(
          style: TextStyle(color: Colors.black, fontSize: 18.0),
          controller: searchTextEditingController,
          decoration: InputDecoration(
            hintText: "Find user",
            hintStyle: TextStyle(color: Colors.black45),
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey)),
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white)),
            filled: true,
            prefixIcon: Icon(
              Icons.person_pin,
              color: Colors.black,
              size: 30.0,
            ),
            suffixIcon: IconButton(
                icon: Icon(
                  Icons.clear,
                  color: Colors.black,
                ),
                onPressed: () {
                  searchTextEditingController.clear();
                  setState(() {
                    hasAlreadyChatWithSomeone = hasAlreadyChatWithSomeone;
                    searchName = "";
                  });
                }),
          ),
          onChanged: (value) {
            setState(() {
              searchName = value;
            });
          },
        ),
      ),
      automaticallyImplyLeading: false,
      actions: <Widget>[
        IconButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) {
                return Setting();
              }));
            },
            icon: Icon(
              Icons.settings,
              size: 30.0,
              color: Colors.black,
            ))
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: Header(),
        body: searchName == ""
            //futureSearchResult == null
            ? NoSearchResultScreen()
            : FoundUserScreen(),
      ),
    );
  }

  NoSearchResultScreen() {
    try {
      //final Orientation orientation = MediaQuery.of(context).orientation;
      //print("hasAlreadyChatWithSomeone: $hasAlreadyChatWithSomeone");
      return hasAlreadyChatWithSomeone
          ? StreamBuilder<QuerySnapshot>(
              stream: (FirebaseFirestore.instance
                  .collection("user")
                  .where("id", isEqualTo: currentUserId)
                  .snapshots()),
              builder: (context, snapshot) {
                //Start Fix
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: circularProgress(),
                  );
                }
                if (snapshot.hasData) {
                  List<ProfileChatWith> usersChattedList = [];
                  chatWithList = [];
                  final chatWithSnapshot =
                      snapshot.data?.docs.first['chatWith'];

                  bool updateNewChatList =
                      snapshot.data?.docs.first['updateNewChatList'];
                  //print("updateNewChatList: $updateNewChatList");

                  if (updateNewChatList == true) {
                    FirebaseFirestore.instance
                        .collection("user")
                        .doc(currentUserId)
                        .update({"updateNewChatList": false});
                    /*
                  new Timer.periodic(new Duration(seconds: 5), (Timer t) {
                    if (!mounted) {
                      return;
                    }
                    return setState(() {
                      NoSearchResultScreen();
                    });
                  });
                   */
                    try {
                      if (!mounted) {}
                      setState(() {
                        //try reassamble();
                        NoSearchResultScreen();
                      });
                    } on Exception catch (_) {
                      Fluttertoast.showToast(msg: "Error. Please try again!");
                      //print("Error");
                    }
                  }

                  //print("chatWithSnapshot: $chatWithSnapshot");
                  for (var userChatWith in chatWithSnapshot) {
                    final user = new ProfileChatWith(
                      userId: userChatWith,
                      currentUserId: currentUserId,
                    );
                    //usersChattedList = arrangeChattedList(chatWithSnapshot);
                    chatWithList.add(user);
                    usersChattedList.add(user);
                    //print("I have chatted with: $userChatWith");
                    //chatWithList.fillRange(0, usersChattedList.length, user);
                  }
                  //for (var item in usersChattedList) {print("Item: ${item.userId}");}

                  chatWithList.replaceRange(
                      0, chatWithList.length, usersChattedList);
                  return Container(
                    width: MediaQuery.of(context).size.width,
                    child: new ListView.builder(
                      //shrinkWrap: true,
                      itemCount: chatWithList.length,
                      itemBuilder: (context, index) => chatWithList[index],
                    ),

                    /*
                  ListView(
                    //shrinkWrap: true,
                    children: chatWithList,
                  ),

                   */
                  );
                } else {
                  return Center(
                    child: circularProgress(),
                  );
                }
              },
            )
          : Container(
              child: Center(
                child: ListView(
                  shrinkWrap: true,
                  children: <Widget>[
                    Icon(
                      Icons.group,
                      color: Colors.greenAccent,
                      size: 200.0,
                    ),
                    Text(
                      "Search Users",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 50.0,
                          fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              ),
            );
    } on Exception catch (e) {
      //print(e);
    }
  }

  FoundUserScreen() {
    return StreamBuilder<QuerySnapshot>(
      stream: (searchName != "" && searchName != null)
          ? FirebaseFirestore.instance
              .collection("user")
              .where(
                "searchID",
                arrayContains: searchName.toLowerCase().replaceAll(' ', ''),
              )
              .snapshots()
          : FirebaseFirestore.instance.collection("user").snapshots(),
      builder: (context, snapshot) {
        return (snapshot.connectionState == ConnectionState.waiting)
            ? Center(
                child: circularProgress(),
              )
            : Container(
                width: MediaQuery.of(context).size.width,
                child: ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      DocumentSnapshot data = snapshot.data!.docs[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          ListTile(
                            title: Text(
                              data["name"],
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black),
                            ),
                            subtitle: Text(
                              data["about"],
                              style: TextStyle(
                                  fontSize: 15.0,
                                  fontWeight: FontWeight.w300,
                                  color: Colors.black),
                            ),
                            leading: Container(
                              height: 78.0,
                              width: 78.0,
                              child: CircleAvatar(
                                  radius: 34.0,
                                  backgroundImage:
                                      NetworkImage(data["photoUrl"])),
                            ), //Container
                            onTap: () {
                              Navigator.push(context,
                                  MyRoute(builder: (context) {
                                return Chat(
                                  receiverId: data["id"],
                                  receiverName: data["name"],
                                  receiverProfileImg: data["photoUrl"],
                                  receiverAbout: data["about"],
                                );
                              }));
                            },
                          ),
                        ],
                      );
                    }),
              );
      },
    );
  }
}
