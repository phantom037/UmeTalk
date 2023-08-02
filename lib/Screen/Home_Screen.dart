import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:ume_talk/Models/screenTransition.dart';
import 'package:ume_talk/Models/themeColor.dart';
import 'package:ume_talk/Screen/Chat_Screen.dart';
import 'package:ume_talk/Screen/Setting_Screen.dart';
import 'package:ume_talk/Widgets/ChatWithProfile_Widget.dart';
import 'package:ume_talk/Widgets/Progress_Widget.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:new_version/new_version.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../Models/themeData.dart';

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
  late bool hasAlreadyChatWithSomeone = false, darkMode = false;
  late SharedPreferences preference;

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
    //checkVersion();
    ErrorWidget.builder = (FlutterErrorDetails details) => Container();
    //NotificationAPI.init();
    registerNotification();
    configureLocalNotification();
    getThemeMode();
  }

  /*
  void listenNotifications() =>
      NotificationAPI.onNotification.stream.listen(onClickedNotification);

  void onClickedNotification(String? payload) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (context) {
        return SettingsScreen();
      }));

   */

  void getThemeMode() async {
    preference = await SharedPreferences.getInstance();
    try{
      setState(() {
        darkMode = preference.getBool('darkMode') ??
            false; // set a default value of true if it hasn't been set before
      });
    }on Exception catch (e){
      darkMode = false;
    }
  }

  ///Add async
  void registerNotification() async {
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
    var version = "2.2.1";
    // Instantiate NewVersion manager object (Using GCP Console app as example)
    final newVersion = NewVersion(
      iOSId: 'com.leotran9x.umeTalk',
      androidId: 'com.leotran9x.ume_talk',
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

    var idChatWith = [];
    if (snapshot["chatWith"] != null) {
      setState(() {
        hasAlreadyChatWithSomeone = true;
      });
    }
  }

  void deleteChat(String chattedUserId) async {
    var senderSnapshot = await FirebaseFirestore.instance
        .collection("user")
        .doc(currentUserId)
        .get();
    var currentUserChattedList = [];
    for (var user in senderSnapshot["chatWith"]) {
      currentUserChattedList.add(user);
    }
    currentUserChattedList.remove(chattedUserId);
    await FirebaseFirestore.instance
        .collection("user")
        .doc(currentUserId)
        .update({"chatWith": currentUserChattedList});

    await FirebaseFirestore.instance
        .collection("user")
        .doc(currentUserId)
        .update({"updateNewChatList": true});
  }

  Header() {
    return AppBar(
      backgroundColor: themeColor,
      title: Container(
        margin: const EdgeInsets.only(bottom: 4.0),
        child: TextFormField(
          style: const TextStyle(color: Colors.black, fontSize: 18.0),
          controller: searchTextEditingController,
          decoration: InputDecoration(
            hintText: "Find user",
            hintStyle: const TextStyle(color: Colors.black),
            enabledBorder: const UnderlineInputBorder(
                borderSide: const BorderSide(color: Colors.black54)),
            focusedBorder: const UnderlineInputBorder(
                borderSide: const BorderSide(color: Colors.black87)),
            filled: true,
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: Colors.black,
              size: 30.0,
            ),
            suffixIcon: IconButton(
                icon: const Icon(
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
            icon: const Icon(
              Icons.settings,
              size: 30.0,
              color: Colors.black,
            ),
          splashRadius: 0.1, // Set a small value to disable the ripple effect
          highlightColor: Colors.transparent, // Disable the highlight color
          hoverColor: Colors.transparent,
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final userThemeData = Provider.of<UserThemeData>(context);
    darkMode = userThemeData.updatedValue;
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: darkMode ? Colors.black : backgroundColor,
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
      return hasAlreadyChatWithSomeone
          ? StreamBuilder<QuerySnapshot>(
              stream: (FirebaseFirestore.instance
                  .collection("user")
                  .where("id", isEqualTo: currentUserId)
                  .snapshots()),
              builder: (context, snapshot) {
                //Start Fix
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                      color: darkMode ? Colors.black : backgroundColor,
                      child: Center(
                      child: circularProgress(),
                    ),
                  );
                }
                if (snapshot.hasData) {
                  List<ProfileChatWith> usersChattedList = [];
                  chatWithList = [];
                  final chatWithSnapshot =
                      snapshot.data?.docs.first['chatWith'];

                  bool updateNewChatList =
                      snapshot.data?.docs.first['updateNewChatList'];

                  if (updateNewChatList == true) {
                    FirebaseFirestore.instance
                        .collection("user")
                        .doc(currentUserId)
                        .update({"updateNewChatList": false});

                    if (mounted) {
                      try {
                        WidgetsBinding.instance?.addPostFrameCallback((_) {
                          setState(() {
                            NoSearchResultScreen();
                          });
                        });
                      } on Exception catch (_) {
                        Fluttertoast.showToast(msg: "Error. Please try again!");
                      }
                    }
                  }

                  for (var userChatWith in chatWithSnapshot) {
                    final user = new ProfileChatWith(
                      chattedUserId: userChatWith,
                      currentUserId: currentUserId,
                      darkMode: darkMode,
                    );
                    chatWithList.add(user);
                    usersChattedList.add(user);
                  }
                  chatWithList.replaceRange(
                      0, chatWithList.length, usersChattedList);
                  return Container(
                    color: darkMode ? Colors.black : backgroundColor,
                    width: MediaQuery.of(context).size.width,
                    child: new ListView.builder(
                        itemCount: chatWithList.length,
                        itemBuilder: (context, index) {
                          final item = chatWithList[index];

                          return Slidable(
                            // The start action pane is the one at the left or the top side.
                            endActionPane: ActionPane(
                              // A motion is a widget used to control how the pane animates.
                              motion: const ScrollMotion(),
                              extentRatio: 0.4,
                              // A pane can dismiss the Slidable.
                              //dismissible: DismissiblePane(onDismissed: () {}),

                              // All actions are defined in the children parameter.
                              children: [
                                // A SlidableAction can have an icon and/or a label.
                                SlidableAction(
                                  onPressed: (context) async {
                                    chatWithList.removeAt(index);
                                    usersChattedList.removeAt(index);
                                    deleteChat(item.chattedUserId);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text("Block")));
                                  },
                                  backgroundColor: Color(0xff636e72),
                                  foregroundColor: Colors.white,
                                  icon: Icons.block,
                                  label: 'Block',
                                ),
                                SlidableAction(
                                  onPressed: (context) async {
                                    chatWithList.removeAt(index);
                                    usersChattedList.removeAt(index);
                                    deleteChat(item.chattedUserId);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text("Deleted")));
                                  },
                                  backgroundColor: Color(0xFFFE4A49),
                                  foregroundColor: Colors.white,
                                  icon: Icons.delete,
                                  label: 'Delete',
                                ),
                              ],
                            ),
                              child: chatWithList[index],

                          );

                          /*
                          return Dismissible(
                            key: Key(item.toString()),
                            direction: DismissDirection.endToStart,
                            onDismissed: (direction) {
                              setState(() async {
                                chatWithList.removeAt(index);
                                usersChattedList.removeAt(index);
                                deleteChat(item.chattedUserId);
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Deleted")));
                            },

                            background: Container(
                              color: Colors.red,
                              child: Padding(
                                padding: EdgeInsets.all(25),
                                child: Text(
                                  "Slide to delete",
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      fontWeight: FontWeight.w300,
                                      color: Colors.black,
                                      fontSize: 15.0),
                                ),
                              ),
                            ),
                            child: chatWithList[index],
                          );
                          */
                        }
                        //=> chatWithList[index]
                        ),
                  );
                } else {
                  return Container(
                    color: darkMode ? Colors.black : backgroundColor,
                    child: Center(
                      child: circularProgress(),
                    ),
                  );
                }
              },
            )
          : Container(
              color: darkMode ? Colors.black : backgroundColor,
              child: Center(
                child: ListView(
                    shrinkWrap: true,
                    children: <Widget>[
                      const Icon(
                        Icons.group,
                        color: themeColor,
                        size: 200.0,
                      ),
                      const Text(
                        "Get Started",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: themeColor,
                            fontSize: 50.0,
                            fontWeight: FontWeight.bold),
                      )
                    ],
                  ),
              ),
            );
    } on Exception catch (e) {}
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
            ? Container(
          color: darkMode ? Colors.black : backgroundColor,
              child: Center(
                  child: circularProgress(),
                ),
            )
            : Container(
                color: darkMode ? Colors.black : backgroundColor,
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
                                  color: darkMode ? Colors.white : Colors.black),
                            ),
                            subtitle: Text(
                              data["about"],
                              style: const TextStyle(
                                  fontSize: 15.0,
                                  fontWeight: FontWeight.w300,
                                  color: Colors.grey),
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
                              try{
                                Navigator.push(context,
                                    MyRoute(builder: (context) {
                                      return Chat(
                                          receiverId: data["id"],
                                          receiverName: data["name"],
                                          receiverProfileImg: data["photoUrl"],
                                          receiverAbout: data["about"]
                                      );
                                    }));
                              }on Exception catch(e){
                              }
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
