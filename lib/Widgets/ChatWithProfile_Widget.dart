import 'package:flutter/material.dart';
import 'package:ume_talk/Models/screenTransition.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:ume_talk/Models/themeColor.dart';
import 'package:ume_talk/Screen/Chat_Screen.dart';

class ProfileChatWith extends StatefulWidget {
  final String chattedUserId;
  final String currentUserId;
  bool darkMode;
  ProfileChatWith(
      {Key? key, required this.chattedUserId, required this.currentUserId, required this.darkMode})
      : super(key: key);

  @override
  _ProfileChatWithState createState() =>
      _ProfileChatWithState(id: chattedUserId, currentUserId: currentUserId, darkMode: darkMode);
}

class _ProfileChatWithState extends State<ProfileChatWith> {
  String id, currentUserId;
  bool darkMode;
  _ProfileChatWithState({required this.id, required this.currentUserId, required this.darkMode});
  var userData;
  String? profileImgUrl, chatID;
  String profileName = "Loading";
  String latestMessage = "Get Start";
  String profileAbout = "Loading";
  String diff = "loading";

  ///Unused consider delete all relevant
  bool lastMessageSentFromCurrentUserId = true;
  bool userRead = true;
  bool? userHasRead;

  @override
  void initState() {
    readLocal();
    super.initState();
    getUserData();
  }

  readLocal() async {
    if (currentUserId.hashCode <= id.hashCode) {
      chatID = "$currentUserId - $id";
    } else {
      chatID = "$id - $currentUserId";
    }

    //Check if user read message
    Map<String, bool> mapUserRead = {"user access": true};
    await FirebaseFirestore.instance
        .collection("messages")
        .doc(chatID)
        .get()
        .then((element) => {
              element.data()?.forEach((key, value) {
                mapUserRead[key] = value;
              })
            });
    if (!mounted) {
      return;
    }
    setState(() {
      userRead = mapUserRead["user $currentUserId read"] ?? false;
    });

    Map<String, dynamic> lastMessageFromDatabase;
    await FirebaseFirestore.instance
        .collection("messages")
        .doc(chatID)
        .collection(chatID!)
        .orderBy("time", descending: true)
        .limit(1)
        .get()
        .then((QuerySnapshot querySnapshot) => {
              querySnapshot.docs.forEach((element) {
                if (element.data() != null) {
                  lastMessageFromDatabase =
                      element.data() as Map<String, dynamic>;
                  if (!mounted) {
                    return;
                  }
                  setState(() {
                    if (userRead == false) {
                      lastMessageSentFromCurrentUserId = false;
                      latestMessage = "New message";
                    } else {
                      if (lastMessageFromDatabase["type"] == 0) {
                        String temp = lastMessageFromDatabase["content"];
                        if (temp.length < 15) {
                          latestMessage = "You: " + temp;
                        } else {
                          latestMessage = "You: " + temp.substring(0, 15);
                        }
                      } else if (lastMessageFromDatabase["type"] == 1) {
                        latestMessage = "You sent an image";
                      } else {
                        latestMessage = "You sent an icon";
                      }
                    }
                  });
                }
              })
            });
  }

  checkReadMessage() async {
    Map<String, bool> mapUserRead = {"user access": true};
    await FirebaseFirestore.instance
        .collection("messages")
        .doc(chatID)
        .get()
        .then((element) => {
              element.data()?.forEach((key, value) {
                mapUserRead[key] = value;
              })
            });
    userHasRead = mapUserRead["user $currentUserId read"];
  }

  generateLatestMessage() {
    checkReadMessage();
    return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("messages")
            .doc(chatID)
            .collection(chatID!)
            .orderBy("time", descending: true)
            .limit(1)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container();
          }
          try {
            //String temp = DateFormat("dd MMMM, yyyy hh:mm aa").format(DateTime.parse(snapshot.data?.docs.first["time"]).toLocal());
            DateTime messageTime =
                DateTime.parse(snapshot.data?.docs.first["time"]).toLocal();
            DateTime currentTime = DateTime.now().toLocal();
            Duration timeDiff = currentTime.difference(messageTime);

            if (timeDiff.inDays > 0) {
              diff = timeDiff.inDays.toString() + "d";
            } else if (timeDiff.inHours > 0) {
              diff = timeDiff.inHours.toString() + "h";
            } else if (timeDiff.inMinutes > 0) {
              diff = timeDiff.inMinutes.toString() + "m";
            } else if (timeDiff.inSeconds > 0) {
              diff = "now";
            } else {
              diff = " ";
            }
          } on Exception catch (e) {
            print("");
          }
          if (snapshot.hasData) {
            //final chatWithSnapshot = snapshot.data?.docs.first['chatWith'];
            if (userHasRead == false) {
              lastMessageSentFromCurrentUserId = false;
              latestMessage = "New message";
              checkReadMessage();

              ///Notification
              /*
              NotificationAPI.showNotification(
                  title: "From $profileName",
                  body: "Sent you a message",
                  payload: "Ume Talk");
               */
            } else {
              if (snapshot.data?.docs.first["idFrom"] == currentUserId) {
                if (snapshot.data?.docs.first["type"] == 0) {
                  String temp = snapshot.data?.docs.first["content"];
                  if (temp.length < 20) {
                    latestMessage = "You: " + temp;
                  } else {
                    latestMessage = "You: " + temp.substring(0, 20) + "...";
                  }
                } else if (snapshot.data?.docs.first["type"] == 1) {
                  latestMessage = "You sent an image";
                } else {
                  latestMessage = "You sent an icon";
                }
              } else {
                if (snapshot.data?.docs.first["type"] == 0) {
                  String temp = snapshot.data?.docs.first["content"];
                  if (temp.length < 20) {
                    latestMessage = temp;
                  } else {
                    latestMessage = temp.substring(0, 20) + "...";
                  }
                } else if (snapshot.data?.docs.first["type"] == 1) {
                  latestMessage = "You received an image";
                } else {
                  latestMessage = "You received an icon";
                }
              }
            }
          } else {
            return Container();
          }
          return Row(children: <Widget>[
            Container(
              width: MediaQuery.of(context).size.width > 400
                  ? MediaQuery.of(context).size.width / 1.7
                  : MediaQuery.of(context).size.width / 1.9,
              child: Text(
                latestMessage,
                style: userRead
                    ? const TextStyle(color: Colors.grey, fontSize: 15.0)
                    : TextStyle(
                        color: darkMode ? subThemeColor : Colors.black,
                        fontSize: 15.0,
                        fontWeight: FontWeight.bold),
                textAlign: TextAlign.start,
              ),
            ),
            Text(
              diff,
              style: const TextStyle(color: Colors.grey),
            ),
          ]);
        });
  }

  void getUserData() async {
    userData =
        await FirebaseFirestore.instance.collection('user').doc(id).get();
    if (!mounted) {
      return;
    }
    setState(() {
      profileName = userData["name"];
      profileImgUrl = userData["photoUrl"];
      profileAbout = userData["about"];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      child: TextButton(
        onPressed: () {
          Navigator.push(context, MyRoute(builder: (context) {
            return Chat(
              receiverId: id,
              receiverName: profileName.toString(),
              receiverProfileImg: profileImgUrl.toString(),
              receiverAbout: profileAbout.toString()
            );
          }));
        },
        child: Padding(
          padding: const EdgeInsets.only(left: 12.0, right: 12.0),
          child: Container(
            width: MediaQuery.of(context).size.width,
            child: Row(
              children: <Widget>[
                Material(
                  child: CachedNetworkImage(
                    imageUrl: (profileImgUrl != null)
                        ? profileImgUrl.toString()
                        : "https://dlmocha.com/app/Ume-Talk/userDefaultAvatar.jpeg",
                    placeholder: (context, url) =>
                        const CircularProgressIndicator(),
                    errorWidget: (context, url, error) => new Icon(Icons.error),
                    width: 60.0,
                    height: 60.0,
                    fit: BoxFit.cover,
                  ),
                  borderRadius: const BorderRadius.all(Radius.circular(125.0)),
                  clipBehavior: Clip.hardEdge,
                ),
                const SizedBox(
                  width: 15.0,
                ),
                Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      AutoSizeText(
                        profileName.toString() != null
                            ? profileName.toString()
                            : "Loading",
                        style: TextStyle(
                          color: darkMode ? Colors.white : Colors.black,
                          fontSize: 15.0,
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.start,
                      ),
                      generateLatestMessage(),
                    ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
