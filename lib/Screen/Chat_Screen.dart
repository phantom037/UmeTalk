import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ume_talk/Models/profileChatList.dart';
import 'package:ume_talk/Models/screenTransition.dart';
import 'package:ume_talk/Models/sticker.dart';
import 'package:ume_talk/Models/themeColor.dart';
import 'package:ume_talk/Screen/Home_Screen.dart';
import 'package:ume_talk/Screen/Profile_Screen.dart';
import 'package:ume_talk/Widgets/ChatWithProfile_Widget.dart';
import 'package:ume_talk/Widgets/Image_Widget.dart';
import 'package:ume_talk/Widgets/Progress_Widget.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';

class Chat extends StatelessWidget {
  final String receiverId;
  final String receiverName;
  final String receiverProfileImg;
  final String receiverAbout;
  Chat(
      {Key? key,
      required this.receiverId,
      required this.receiverName,
      required this.receiverProfileImg,
      required this.receiverAbout})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.greenAccent,
        actions: <Widget>[
          Padding(
            padding: EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundColor: Colors.black,
              backgroundImage: CachedNetworkImageProvider(receiverProfileImg),
              child: FlatButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return ProfileChatWithInfo(
                        name: receiverName,
                        photoUrl: receiverProfileImg,
                        about: receiverAbout);
                  }));
                },
                child: Container(),
              ),
            ),
          )
        ],
        iconTheme: IconThemeData(color: Colors.black),
        title: Text(
          receiverName,
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ChatScreen(
        receiverId: this.receiverId,
        receiverProfileImg: this.receiverProfileImg,
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverProfileImg;
  ChatScreen(
      {Key? key, required this.receiverId, required this.receiverProfileImg})
      : super(key: key);
  @override
  State createState() => ChatScreenState(
      receiverId: this.receiverId, receiverProfileImg: this.receiverProfileImg);
}

class ChatScreenState extends State<ChatScreen> {
  final String receiverId;
  final String receiverProfileImg;
  ChatScreenState(
      {Key? key, required this.receiverId, required this.receiverProfileImg});
  final TextEditingController textEditingController = TextEditingController();
  final ScrollController chatListScrollController = ScrollController();
  final FocusNode focusNode = FocusNode();
  bool isSticker = false, isLoading = false, uploadImageComplete = true;
  File? image;
  String? imageUrl;
  String? chatID, id;
  SharedPreferences? preferences;
  var listMessage;
  List senderChattedList = [], receiverChattedList = [];
  int maxNumberMessages = 20;
  String? profileChatWithName, profileChatWithUrl, profileChatWithAbout;

  @override
  void initState() {
    FlutterAppBadger.removeBadge();
    // TODO: implement initState
    super.initState();
    focusNode.addListener(onFocusChange);
    isSticker = false;
    isLoading = false;
    chatID = "";

    readLocal();
    chatListScrollController.addListener(() {
      //print("Run chatListScrollController");
      if (chatListScrollController.position.pixels ==
          chatListScrollController.position.maxScrollExtent) {
        getMoreData();
      }
    });
  }

  readLocal() async {
    preferences = await SharedPreferences.getInstance();
    id = preferences?.getString("id") ?? "";

    if (id.hashCode <= receiverId.hashCode) {
      setState(() {
        chatID = "$id - $receiverId";
      });
    } else {
      setState(() {
        chatID = "$receiverId - $id";
      });
    }

    FirebaseFirestore.instance
        .collection("user")
        .doc(id)
        .update({"updateNewChatList": false});

    ///Jan 10
    //var snapshot = await FirebaseFirestore.instance.collection("user").doc(id).get();
    // print("ID chat with : ${snapshot["chatWith"]}");

    /*checkChatList
    var idChatWith = [];
    if (snapshot["chatWith"] == null) {
      idChatWith.add(receiverId);
    } else {
      idChatWith = snapshot["chatWith"];
      if (!idChatWith.contains(receiverId)) {
        idChatWith.add(receiverId);
      }
    }

    FirebaseFirestore.instance
        .collection("user")
        .doc(id)
        .update({"chatWith": idChatWith});

     */

    //checkReadMessage();
    //Check if there is no data between sender and receiver
    var checkData = await FirebaseFirestore.instance
        .collection("messages")
        .doc(chatID)
        .get();
    //print("Run run run");
    if (checkData.data() == null) {
      //print("Run IF");
      await FirebaseFirestore.instance
          .collection("messages")
          .doc(chatID)
          .set({"user $id read": true, "user $receiverId read": true});
    }
    //Auto assign read by current user id = true;
    await FirebaseFirestore.instance
        .collection("messages")
        .doc(chatID)
        .update({"user $id read": true});
  }

  void getMoreData() {
    //print("Run getMoreData()");
    setState(() {
      maxNumberMessages += 20;
    });
  }

  ///Unused Check if receiver read the message
  void checkReadMessage() async {
    Map<String, dynamic> lastMessageFromDatabase;
    bool read = false;
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
                  setState(() {
                    read = lastMessageFromDatabase["read"];
                  });
                }
              })
            });
    //print("Read: $read");
    //snapshot.data!.docs[index]
  }

  void updateChatWithForSender() async {
    var snapshot =
        await FirebaseFirestore.instance.collection("user").doc(id).get();
    //print("ID chat with : ${snapshot["chatWith"]}");

    var idChatWith = [];
    if (snapshot["chatWith"] == null) {
      idChatWith.add(receiverId);
    } else {
      idChatWith = snapshot["chatWith"];
      if (!idChatWith.contains(receiverId)) {
        idChatWith.add(receiverId);
      }
    }

    FirebaseFirestore.instance
        .collection("user")
        .doc(id)
        .update({"chatWith": idChatWith});
    updateChatWithList();
  }

  void updateChatWithForReceiver() async {
    var snapshot = await FirebaseFirestore.instance
        .collection("user")
        .doc(receiverId)
        .get();
    //print("ID chat with : ${snapshot["chatWith"]}");

    var idChatWith = [];
    if (snapshot["chatWith"] == null) {
      idChatWith.add(id);
    } else {
      idChatWith = snapshot["chatWith"];
      if (!idChatWith.contains(id)) {
        idChatWith.add(id);
      }
    }

    FirebaseFirestore.instance
        .collection("user")
        .doc(receiverId)
        .update({"chatWith": idChatWith});
  }

  void updateChatWithList() async {
    var senderSnapshot =
        await FirebaseFirestore.instance.collection("user").doc(id).get();
    var receiverSnapshot = await FirebaseFirestore.instance
        .collection("user")
        .doc(receiverId)
        .get();
    //print("ID chat with : ${snapshot["chatWith"]}");
    //print("Run updateChatWithList");

    ///Fix from here
    if (senderSnapshot["chatWith"] != null) {
      setState(() {
        //print("Run IF");
        senderChattedList = [];
        for (var user in senderSnapshot["chatWith"]) {
          senderChattedList.add(user);
        }
      });
    } else {
      senderChattedList.add(receiverId);
    }
    if (receiverSnapshot["chatWith"] != null) {
      setState(() {
        //print("Run IF");
        receiverChattedList = [];
        for (var user in receiverSnapshot["chatWith"]) {
          receiverChattedList.add(user);
        }
      });
    } else {
      receiverChattedList.add(id);
    }
    // ignore: unused_local_variable
    ProfileChatList profileFromSenderChatList = ProfileChatList(
        currentUserId: id,
        idChatWith: receiverId,
        chatWithList: senderChattedList);

    ProfileChatList profileFromReceiverChatList = ProfileChatList(
        currentUserId: receiverId,
        idChatWith: id,
        chatWithList: receiverChattedList);

    FirebaseFirestore.instance
        .collection("user")
        .doc(id)
        .update({"chatWith": profileFromSenderChatList.getChatWithList()});

    FirebaseFirestore.instance
        .collection("user")
        .doc(receiverId)
        .update({"chatWith": profileFromReceiverChatList.getChatWithList()});

    FirebaseFirestore.instance
        .collection("user")
        .doc(receiverId)
        .update({"updateNewChatList": true});
  }

  onFocusChange() {
    if (focusNode.hasFocus) {
      //Hide sticker keyboard
      setState(() {
        isSticker = false;
      });
    }
  }

  void getSticker() {
    focusNode.unfocus();
    setState(() {
      isSticker = !isSticker;
    });
  }

  Future<bool> onPressBack() {
    if (isSticker) {
      setState(() {
        isSticker = false;
      });
    } else {
      Navigator.pushReplacement(
        context,
        MyRoute(
          builder: (context) {
            return HomeScreen(currentUserId: id.toString());
          },
        ),
      );
    }
    return Future.value(false);
  }

  Future getImage(ImageSource sourcePicked) async {
    try {
      final ImagePicker _picker = ImagePicker();
      // Pick an image
      var image = await _picker.pickImage(source: sourcePicked);
      if (image != null) {
        isLoading = true;
        setState(() {
          final imagePicked = File(image.path);
          this.image = imagePicked;
        });
        Fluttertoast.showToast(msg: "Uploading Image");
        uploadImageFile();
      }
    } on PlatformException catch (e) {
      Fluttertoast.showToast(msg: "Failed to pick image");
      //print("Failed to pick image");
    }
  }

  ///Fixed on 26-12
  /*
  disable updateChatWithForReceiver() & updateChatWithForSender()
   */
  Future uploadImageFile() async {
    //updateChatWithForReceiver();
    //updateChatWithForSender();
    String fileName = DateTime.now().toString();
    Reference storageReference =
        FirebaseStorage.instance.ref().child("Chat Images").child(fileName);
    UploadTask storageUploadTask = storageReference.putFile(image!);
    storageUploadTask.then((res) {
      res.ref.getDownloadURL().then((downloadUrl) {
        imageUrl = downloadUrl;
        setState(() {
          isLoading = false;
          onSendMessage(imageUrl!, 1);
        });
      }, onError: (error) {
        setState(() {
          isLoading = false;
        });
        Fluttertoast.showToast(msg: "Error. Can send this image" + error);
      });
    });
  }

  ///Fixed on 26-12
  void onSendMessage(String value, int target) async {
    if (value != "") {
      updateChatWithList();
      //updateChatWithForReceiver();
      //updateChatWithForSender();
      textEditingController.clear();
      var dateTime = DateTime.now();
      var docRef = FirebaseFirestore.instance
          .collection("messages")
          .doc(chatID)
          .collection(chatID!)
          .doc(dateTime.toUtc().toString());
      //print("DateTime.now().millisecondsSinceEpoch.toString(): ${DateTime.now().millisecondsSinceEpoch.toString()}");
      //print("dateTime: $dateTime");
      //print("dateTime.toUtc: ${dateTime.toUtc()}");
      //print("dateTime.timeZoneName: ${dateTime.timeZoneName}");

      //Auto assign read by receiver id = false;
      await FirebaseFirestore.instance
          .collection("messages")
          .doc(chatID)
          .update({"user $receiverId read": false});

      FirebaseFirestore.instance.runTransaction((transaction) async {
        await transaction.set(
          docRef,
          {
            "idFrom": id,
            "idTo": receiverId,
            "time": dateTime.toUtc().toString(),
            "content": value,
            "type": target
          },
        );
      });
      chatListScrollController.animateTo(0.0,
          duration: Duration(microseconds: 300), curve: Curves.easeOut);
    }
  }

  bool isLastReceiveMessage(int index) {
    if ((index > 0 &&
            listMessage != null &&
            listMessage[index - 1]["idFrom"] == id) ||
        index == 0) {
      return true;
    }
    return false;
  }

  bool isLastSenderMessage(int index) {
    if ((index > 0 &&
            listMessage != null &&
            listMessage[index - 1]["idFrom"] != id) ||
        index == 0) {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        return onPressBack();
      },
      child: SafeArea(
        child: Stack(
          children: <Widget>[
            Column(
              children: <Widget>[
                //List of Message
                createListMessage(),
                //Sticker keyboard
                (isSticker ? createSticker() : Container()),
                //Input Controller
                createInput(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  createItem(int index, DocumentSnapshot document) {
    //Sender messages - right side
    if (document["idFrom"] == id) {
      return Padding(
        padding: EdgeInsets.all(3.0),
        child: Row(
          children: <Widget>[
            document["type"] == 0
                //Text Message
                ? Material(
                    child: document["content"].length < 24
                        ? Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: 10.0, horizontal: 20.0),
                            child: Text(
                              document["content"],
                              style: TextStyle(
                                  color: messageTextColor,
                                  fontWeight: FontWeight.w400),
                            ),
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                                Flexible(
                                  fit: FlexFit.loose,
                                  flex: 1,
                                  child: Container(
                                    width: 250.0,
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                          vertical: 10.0, horizontal: 20.0),
                                      child: Text(
                                        document["content"],
                                        style: TextStyle(
                                            color: messageTextColor,
                                            fontWeight: FontWeight.w400),
                                      ),
                                    ),
                                  ),
                                ),
                              ]),
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30.0),
                        bottomLeft: Radius.circular(30.0),
                        bottomRight: Radius.circular(30.0)),
                    color: Colors.greenAccent,
                  )
                : document["type"] == 1
                    //Image Message
                    ? document["content"] != ""
                        ? Container(
                            child: FlatButton(
                              onPressed: () {
                                Navigator.push(context,
                                    MaterialPageRoute(builder: (context) {
                                  return FullPhoto(url: document["content"]);
                                }));
                              },
                              onLongPress: () {},
                              child: Material(
                                child:
                                    /*
                            FadeInImage(
                              placeholder: const NetworkImage("https://upload.wikimedia.org/wikipedia/commons/b/b9/Youtube_loading_symbol_1_(wobbly).gif"),
                              image: NetworkImage(document["content"].toString()),
                              width: 200.0,
                              height: 200.0,
                            ),

                             */

                                    CachedNetworkImage(
                                  imageUrl: document["content"].toString(),
                                  width: 200.0,
                                  height: 200.0,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.greenAccent),
                                    ),
                                    width: 200.0,
                                    height: 200.0,
                                    padding: EdgeInsets.all(70.0),
                                    decoration: BoxDecoration(
                                      color: Colors.grey,
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(8.0)),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Material(
                                    child: Image.network(
                                      "https://static.thenounproject.com/png/504708-200.png",
                                      width: 200.0,
                                      height: 200.0,
                                      fit: BoxFit.cover,
                                    ),
                                    borderRadius: BorderRadius.circular(8.0),
                                    clipBehavior: Clip.hardEdge,
                                  ),
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                                clipBehavior: Clip.hardEdge,
                              ),
                            ),
                            margin: EdgeInsets.only(
                                bottom:
                                    isLastSenderMessage(index) ? 20.0 : 10.0,
                                right: 10.0),
                          )
                        : Container(
                            child: Image.network(
                              "https://upload.wikimedia.org/wikipedia/commons/b/b9/Youtube_loading_symbol_1_(wobbly).gif",
                              width: 100.0,
                              height: 100.0,
                              fit: BoxFit.cover,
                            ),
                            margin: EdgeInsets.only(
                                bottom:
                                    isLastSenderMessage(index) ? 20.0 : 10.0,
                                right: 10.0),
                          )
                    //Emoji
                    : Container(
                        child: Image.network(
                          document["content"],
                          width: 100.0,
                          height: 100.0,
                          fit: BoxFit.cover,
                        ),
                        margin: EdgeInsets.only(
                            bottom: isLastSenderMessage(index) ? 20.0 : 10.0,
                            right: 10.0),
                      ),
            Text(
              "✓",
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 10.0,
                  fontWeight: FontWeight.bold),
            )
          ],
          mainAxisAlignment: MainAxisAlignment.end,
        ),
      );
    } else {
      //Receiver messages - left side
      return Container(
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                isLastReceiveMessage(index)
                    ? Material(
                        //Display Receive Profile Img
                        child: CachedNetworkImage(
                          imageUrl: receiverProfileImg,
                          width: 35.0,
                          height: 35.0,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.greenAccent),
                            ),
                            width: 35.0,
                            height: 35.0,
                            padding: EdgeInsets.all(10.0),
                          ),
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(18.0)),
                        clipBehavior: Clip.hardEdge,
                      )
                    : Container(
                        width: 35.0,
                      ),
                //Display Message
                document["type"] == 0
                    //Text Message
                    ? Material(
                        child: document["content"].length < 24
                            ? Padding(
                                padding: EdgeInsets.symmetric(
                                    vertical: 10.0, horizontal: 20.0),
                                child: Text(
                                  document["content"],
                                  style: TextStyle(
                                      color: messageTextColor,
                                      fontWeight: FontWeight.w400),
                                ),
                              )
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                    Flexible(
                                      flex: 1,
                                      fit: FlexFit.loose,
                                      child: Container(
                                        width: 250.0,
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 10.0, horizontal: 20.0),
                                          child: Text(
                                            document["content"],
                                            style: TextStyle(
                                                color: messageTextColor,
                                                fontWeight: FontWeight.w400),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ]),
                        borderRadius: BorderRadius.only(
                            topRight: Radius.circular(30.0),
                            bottomLeft: Radius.circular(30.0),
                            bottomRight: Radius.circular(30.0)),
                        color: Colors.grey[200],
                        /*
                        padding: EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 10.0),
                        width: 200.0,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.only(
                              topRight: Radius.circular(30.0),
                              bottomLeft: Radius.circular(30.0),
                              bottomRight: Radius.circular(30.0)),
                        ),
                        margin: EdgeInsets.only(left: 10.0),

                         */
                      )
                    : document["type"] == 1
                        //Image Message
                        ? Container(
                            child: FlatButton(
                              onPressed: () {
                                Navigator.push(context,
                                    MaterialPageRoute(builder: (context) {
                                  return FullPhoto(url: document["content"]);
                                }));
                              },
                              child: Material(
                                child: CachedNetworkImage(
                                  imageUrl: document["content"].toString(),
                                  width: 200.0,
                                  height: 200.0,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.greenAccent),
                                    ),
                                    width: 200.0,
                                    height: 200.0,
                                    padding: EdgeInsets.all(70.0),
                                    decoration: BoxDecoration(
                                      color: Colors.grey,
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(8.0)),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Material(
                                    child: Image.network(
                                      "https://static.thenounproject.com/png/504708-200.png",
                                      width: 200.0,
                                      height: 200.0,
                                      fit: BoxFit.cover,
                                    ),
                                    borderRadius: BorderRadius.circular(8.0),
                                    clipBehavior: Clip.hardEdge,
                                  ),
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                                clipBehavior: Clip.hardEdge,
                              ),
                            ),
                            margin: EdgeInsets.only(left: 10.0),
                          ) //Emoji
                        : Container(
                            child: Image.network(
                              document["content"],
                              width: 100.0,
                              height: 100.0,
                              fit: BoxFit.cover,
                            ),
                            margin: EdgeInsets.only(left: 10.0),
                          )
              ],
            ),
            isLastReceiveMessage(index)
                ? Container(
                    child: Text(
                      //dd MMMM, yyyy - kk:mm:aa
                      DateFormat("dd MMMM, yyyy hh:mm aa")
                          .format(DateTime.parse(document["time"]).toLocal()),
                      style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12.0,
                          fontStyle: FontStyle.italic),
                    ),
                    margin: EdgeInsets.only(left: 50.0, top: 5.0, bottom: 5.0),
                  )
                : Container()
          ],
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
        margin: EdgeInsets.only(bottom: 3.0, top: 3.0),
      );
    }
  }

  createLoading() {
    return Positioned(
      child: isLoading ? circularProgress() : Container(),
    );
  }

  createSticker() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey, width: 0.5),
        ),
        color: Colors.white,
      ),
      padding: EdgeInsets.all(5.0),
      height: 180.0,
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              FlatButton(
                onPressed: () {
                  onSendMessage(
                      "https://i.giphy.com/media/TGXoYOYmVQ9v6M3g1q/200w.webp",
                      2);
                },
                child: Container(
                    width: 50.0,
                    height: 50.0,
                    child: Image.network(
                        "https://i.giphy.com/media/TGXoYOYmVQ9v6M3g1q/200w.webp")),
              ),
              FlatButton(
                onPressed: () {
                  onSendMessage(
                      "https://i.giphy.com/media/hof5uMY0nBwxyjY9S2/200w.webp",
                      2);
                },
                child: Container(
                    width: 50.0,
                    height: 50.0,
                    child: Image.network(
                        "https://i.giphy.com/media/hof5uMY0nBwxyjY9S2/200w.webp")),
              ),
              FlatButton(
                onPressed: () {
                  onSendMessage(
                      "https://i.giphy.com/media/fSM1fAZJOixky6npXS/200w.webp",
                      2);
                },
                child: Container(
                    width: 50.0,
                    height: 50.0,
                    child: Image.network(
                        "https://i.giphy.com/media/fSM1fAZJOixky6npXS/200w.webp")),
              ),
              FlatButton(
                onPressed: () {
                  onSendMessage(
                      "https://media2.giphy.com/media/cNqBzFAC3aU2gDuD4k/giphy.gif",
                      2);
                },
                child: Container(
                    width: 50.0,
                    height: 50.0,
                    child: Image.network(
                        "https://media2.giphy.com/media/cNqBzFAC3aU2gDuD4k/giphy.gif")),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              FlatButton(
                onPressed: () {
                  onSendMessage(
                      "https://i.giphy.com/media/dxyawae0djPD2CTNyS/200w.webp",
                      2);
                },
                child: Container(
                    width: 50.0,
                    height: 50.0,
                    child: Image.network(
                        "https://i.giphy.com/media/dxyawae0djPD2CTNyS/200w.webp")),
              ),
              FlatButton(
                onPressed: () {
                  onSendMessage(
                      "https://i.giphy.com/media/N9DtPOsLaly1qa5XSn/200w.webp",
                      2);
                },
                child: Container(
                    width: 50.0,
                    height: 50.0,
                    child: Image.network(
                        "https://i.giphy.com/media/N9DtPOsLaly1qa5XSn/200w.webp")),
              ),
              FlatButton(
                onPressed: () {
                  onSendMessage(
                      "https://i.giphy.com/media/ZNKPqTHlEN4KQ/200w.webp", 2);
                },
                child: Container(
                    width: 50.0,
                    height: 50.0,
                    child: Image.network(
                        "https://i.giphy.com/media/ZNKPqTHlEN4KQ/200w.webp")),
              ),
              FlatButton(
                onPressed: () {
                  onSendMessage(
                      "https://media3.giphy.com/media/hp3dmEypS0FaoyzWLR/200w.webp",
                      2);
                },
                child: Container(
                    width: 50.0,
                    height: 50.0,
                    child: Image.network(
                        "https://media3.giphy.com/media/hp3dmEypS0FaoyzWLR/200w.webp")),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              FlatButton(
                onPressed: () {
                  onSendMessage(
                      "https://media4.giphy.com/media/IzcFv6WJ4310bDeGjo/200w.webp",
                      2);
                },
                child: Container(
                    width: 50.0,
                    height: 50.0,
                    child: Image.network(
                        "https://media4.giphy.com/media/IzcFv6WJ4310bDeGjo/200w.webp")),
              ),
              FlatButton(
                onPressed: () {
                  onSendMessage(
                      "https://media0.giphy.com/media/LOnt6uqjD9OexmQJRB/200w.webp",
                      2);
                },
                child: Container(
                    width: 50.0,
                    height: 50.0,
                    child: Image.network(
                        "https://media0.giphy.com/media/LOnt6uqjD9OexmQJRB/200w.webp")),
              ),
              FlatButton(
                onPressed: () {
                  onSendMessage(
                      "https://media4.giphy.com/media/mBkOh02yl747xbahsT/200w.webp",
                      2);
                },
                child: Container(
                    width: 50.0,
                    height: 50.0,
                    child: Image.network(
                        "https://media4.giphy.com/media/mBkOh02yl747xbahsT/200w.webp")),
              ),
              FlatButton(
                onPressed: () {
                  onSendMessage(
                      "https://media0.giphy.com/media/jVIKa3erp2SqgmmrAK/200w.webp",
                      2);
                },
                child: Container(
                    width: 50.0,
                    height: 50.0,
                    child: Image.network(
                        "https://media0.giphy.com/media/jVIKa3erp2SqgmmrAK/200w.webp")),
              ),
            ],
          ),
        ],
      ),
    );
  }

  ///Fix .orderBy("time", descending: true).limit(20).snapshots(),
  createListMessage() {
    //Set message as read
    //print("ChatID: $chatID");
    return Flexible(
        child: chatID == ""
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                ),
              )
            : StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("messages")
                    .doc(chatID)
                    .collection(chatID!)
                    .orderBy("time", descending: true)
                    .limit(maxNumberMessages)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    // print("No data");
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                      ),
                    );
                  } else {
                    //print("Has data");
                    FirebaseFirestore.instance
                        .collection("messages")
                        .doc(chatID)
                        .update({"user $id read": true});
                    listMessage = snapshot.data!.docs;
                    return ListView.builder(
                      //itemExtent: 20,
                      padding: EdgeInsets.all(10.0),
                      itemBuilder: (context, index) {
                        if (index == listMessage.length) {
                          return CupertinoActivityIndicator();
                        }
                        return createItem(index, snapshot.data!.docs[index]);
                      },
                      itemCount: snapshot.data!.docs.length,
                      reverse: true,
                      controller: chatListScrollController,
                    );
                  }
                },
              ));
  }

  createInput() {
    return Container(
      child: Row(
        children: <Widget>[
          //Image Picker Button
          Material(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 1.0),
              child: IconButton(
                icon: Icon(Icons.camera_alt_outlined),
                color: Colors.greenAccent,
                onPressed: () {
                  getImage(ImageSource.camera);
                },
              ),
            ),
            color: Colors.white,
          ),
          Material(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 1.0),
              child: IconButton(
                icon: Icon(Icons.image),
                color: Colors.greenAccent,
                onPressed: () {
                  getImage(ImageSource.gallery);
                },
              ),
            ),
            color: Colors.white,
          ),
          //Emoji Button
          Material(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 1.0),
              child: IconButton(
                icon: Icon(Icons.face_outlined),
                color: Colors.greenAccent,
                onPressed: () {
                  getSticker();
                },
              ),
            ),
            color: Colors.white,
          ),
          //Text Message Field
          Flexible(
              child: Container(
            child: TextField(
              //keyboardType: TextInputType.multiline,
              //maxLines: 5,
              style: TextStyle(
                color: messageTextColor,
                fontSize: 15.0,
              ),
              controller: textEditingController,
              decoration: InputDecoration.collapsed(
                  hintText: "Type Message",
                  hintStyle: TextStyle(color: Colors.grey)),
              focusNode: focusNode,
            ),
          )),
          //Send Message Button
          Material(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 8.0),
              child: IconButton(
                icon: Icon(Icons.send),
                color: Colors.greenAccent,
                onPressed: () {
                  onSendMessage(textEditingController.text, 0);
                },
              ),
            ),
            color: Colors.white,
          ),
        ],
      ),
      width: double.infinity,
      height: 50.0,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey,
            width: 0.5,
          ),
        ),
        color: Colors.white,
      ),
    );
  }
}
