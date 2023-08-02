import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ume_talk/Models/profileChatList.dart';
import 'package:ume_talk/Models/screenTransition.dart';
import 'package:ume_talk/Models/themeColor.dart';
import 'package:ume_talk/Screen/Home_Screen.dart';
import 'package:ume_talk/Screen/Profile_Screen.dart';
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
    return ChatScreen(
        receiverId: this.receiverId,
        receiverProfileImg: this.receiverProfileImg,
        receiverName: this.receiverName,
        receiverAbout: this.receiverAbout
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverProfileImg;
  final String receiverName;
  final String receiverAbout;
  ChatScreen(
      {Key? key, required this.receiverId, required this.receiverProfileImg, required this.receiverName, required this.receiverAbout})
      : super(key: key);
  @override
  State createState() => ChatScreenState(
      receiverId: this.receiverId, receiverProfileImg: this.receiverProfileImg, receiverName: this.receiverName, receiverAbout: this.receiverAbout);
}

class ChatScreenState extends State<ChatScreen> {
  final String receiverId;
  final String receiverProfileImg;
  final String receiverName;
  final String receiverAbout;
  ChatScreenState(
      {Key? key, required this.receiverId, required this.receiverProfileImg, required this.receiverName, required this.receiverAbout});
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
  int maxNumberMessages = 15;
  String? profileChatWithName, profileChatWithUrl, profileChatWithAbout;
  var senderSnapshot;
  var receiverSnapshot;
  late bool darkMode = false;

  @override
  void initState() {
    FlutterAppBadger.removeBadge();
    super.initState();
    getThemeMode();
    focusNode.addListener(onFocusChange);
    isSticker = false;
    isLoading = false;
    chatID = "";

    readLocal();
    chatListScrollController.addListener(() {
      if (chatListScrollController.position.pixels ==
          chatListScrollController.position.maxScrollExtent) {
        getMoreData();
      }
    });
  }

  void getThemeMode() async {
    preferences = await SharedPreferences.getInstance();
    darkMode = preferences?.getBool('darkMode') ??
        false; // set a default value of true if it hasn't been set before
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
    //Move from updateChatWithList
    senderSnapshot =
        await FirebaseFirestore.instance.collection("user").doc(id).get();

    //Move from updateChatWithList
    receiverSnapshot = await FirebaseFirestore.instance
        .collection("user")
        .doc(receiverId)
        .get();

    //Write to current user data that list order won't need to update
    FirebaseFirestore.instance
        .collection("user")
        .doc(id)
        .update({"updateNewChatList": false});

    //Read data of all time-communication transaction
    var firebase =
        await FirebaseFirestore.instance.collection("messages").doc(chatID);

    var checkData = await firebase.get();

    //Check if there is no data between sender and receiver
    if (checkData.data() == null) {
      firebase.set({"user $id read": true, "user $receiverId read": true});
    }

    //Write to time-communication transaction that current user had read message
    //Auto assign read by current user id = true;
    firebase.update({"user $id read": true});

    /*
    //Check if there is no data between sender and receiver
    var checkData = await FirebaseFirestore.instance
        .collection("messages")
        .doc(chatID)
        .get();

    if (checkData.data() == null) {
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
     */
  }

  void getMoreData() {
    setState(() {
      maxNumberMessages += 15;
    });
  }

  Future updateChatWithList() async {
    /*
    var senderSnapshot =
        await FirebaseFirestore.instance.collection("user").doc(id).get();

    var receiverSnapshot = await FirebaseFirestore.instance
        .collection("user")
        .doc(receiverId)
        .get();
     */
    //Read user data and use for update chat list in below code
    if (senderSnapshot["chatWith"] != null) {
      setState(() {
        senderChattedList = [];
        for (var user in senderSnapshot["chatWith"]) {
          senderChattedList.add(user);
        }
      });
    } else {
      senderChattedList.add(receiverId);
    }

    //Read target data and use for update chat list in below code
    if (receiverSnapshot["chatWith"] != null) {
      setState(() {
        receiverChattedList = [];
        for (var user in receiverSnapshot["chatWith"]) {
          receiverChattedList.add(user);
        }
      });
    } else {
      receiverChattedList.add(id);
    }

    ProfileChatList profileFromSenderChatList = ProfileChatList(
        currentUserId: id,
        idChatWith: receiverId,
        chatWithList: senderChattedList);

    ProfileChatList profileFromReceiverChatList = ProfileChatList(
        currentUserId: receiverId,
        idChatWith: id,
        chatWithList: receiverChattedList);

    //Write to user data new update chat list
    FirebaseFirestore.instance
        .collection("user")
        .doc(id)
        .update({"chatWith": profileFromSenderChatList.getChatWithList()});

    //Write to target data new update chat list
    FirebaseFirestore.instance
        .collection("user")
        .doc(receiverId)
        .update({"chatWith": profileFromReceiverChatList.getChatWithList()});

    //Write to target data that chat list was modified  (new message)
    FirebaseFirestore.instance
        .collection("user")
        .doc(receiverId)
        .update({"updateNewChatList": true});
    //print("updateChatWithList");
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
        //imageUploadingAnimation();
        isLoading = true;
        setState(() {
          final imagePicked = File(image.path);
          this.image = imagePicked;
        });
        //Fluttertoast.showToast(toastLength: Toast.LENGTH_LONG, msg: "Uploading Image");
        uploadImageFile();
      }
    } on PlatformException catch (e) {
      isLoading = false;
      Fluttertoast.showToast(
          toastLength: Toast.LENGTH_LONG,
          msg: "Failed to pick image");
    }
  }

  void imageUploadingAnimation(){
    var dateTime = DateTime.now();
    final data = {
      'type': 1,
      'content': 'https://i.stack.imgur.com/rl8Hf.png',
      'idFrom' : id,
      'idTo' : receiverId,
      'time' : dateTime.toUtc().toString(),
      'like': false,
    };
    var temp = FirebaseFirestore.instance
        .collection("messages")
        .doc(chatID)
        .collection(chatID!)
        .orderBy("time", descending: true)
        .limit(1)
        .snapshots();
    //print("temp: $temp");
    //DocumentSnapshot<Map<String, dynamic>> jsonString = data as DocumentSnapshot<Map<String, String>>;
    listMessage.add(data);
    //print(listMessage[listMessage.length() - 1]);
  }

  Future uploadImageFile() async {
    String fileName = DateTime.now().toString();
    Reference storageReference =
        FirebaseStorage.instance.ref().child("Chat Images").child(fileName);
    UploadTask storageUploadTask = storageReference.putFile(image!);
    storageUploadTask.then((res) {
      res.ref.getDownloadURL().then((downloadUrl) {
        imageUrl = downloadUrl;
        setState(() {
          isLoading = false;
          //print("Is Loading: $isLoading");
          listMessage.removeLast();
          onSendMessage(imageUrl!, 1);
        });
      }, onError: (error) {
        setState(() {
          isLoading = false;
          listMessage.removeLast();
          //print("Is Loading: $isLoading");
        });
        Fluttertoast.showToast(msg: "Error. Can send this image" + error);
      });
    });
  }

  void onSendMessage(String value, int target) async {
    if (value != "") {
      textEditingController.clear();
      var dateTime = DateTime.now();
      var docRef = FirebaseFirestore.instance
          .collection("messages")
          .doc(chatID)
          .collection(chatID!)
          .doc(dateTime.toUtc().toString());
      updateChatWithList();
      FirebaseFirestore.instance.runTransaction((transaction) async {
        await transaction.set(
          docRef,
          {
            "idFrom": id,
            "idTo": receiverId,
            "like": false,
            "time": dateTime.toUtc().toString(),
            "content": value,
            "type": target
          },
        );
      });
      chatListScrollController.animateTo(0.0,
          duration: Duration(microseconds: 100), curve: Curves.easeOut);
      ////Write to target data to update that new message was sent
      await FirebaseFirestore.instance
          .collection("messages")
          .doc(chatID)
          .update({"user $receiverId read": false});
      //updateChatWithList();
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
    return Scaffold(
      backgroundColor: darkMode ? Colors.black : backgroundColor,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(55.0),
        child: AppBar(
          leading: IconButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) {
                return HomeScreen(currentUserId: id.toString()); //HomeScreen(currentUserId: preferences.getString("id").toString());
              }));
            },
            icon: const Icon(Icons.arrow_back_ios_new),
            color: Colors.black,
            splashRadius: 0.1, // Set a small value to disable the ripple effect
            highlightColor: Colors.transparent, // Disable the highlight color
            hoverColor: Colors.transparent, // Disable the hover color
          ),
          backgroundColor: themeColor,
          actions: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: CircleAvatar(
                backgroundColor: Colors.black,
                backgroundImage: CachedNetworkImageProvider(receiverProfileImg),
                child: TextButton(
                  onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                          return ProfileChatWithInfo(
                            id: id.toString(),
                              receiverId: receiverId,
                              name: receiverName,
                              photoUrl: receiverProfileImg,
                              about: receiverAbout);
                        }));
                  },
                  style: ButtonStyle(
                    splashFactory: NoSplash.splashFactory,
                    overlayColor: MaterialStateProperty.all(Colors.transparent),
                  ),
                  child: Container(),
                ),
              ),
            )
          ],
          iconTheme: const IconThemeData(color: Colors.black),
          title: Text(
            receiverName,
            style: const TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
      ),
      body: WillPopScope(
        onWillPop: () {
          return onPressBack();
        },
        child: SafeArea(
          child: Stack(
            children: <Widget>[
              isLoading? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                Center(child: Container(child: circularProgress(),)),
                SizedBox(height: 30,),
                Text("Uploading Image", style: TextStyle(fontSize: 15, color: darkMode ? Colors.white : Colors.black),),
              ])

              : Column(
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
      ),
    );
  }

  createItem(int index, DocumentSnapshot document) {
    //print("\n\n=========================================");
    Map<String, dynamic>? data = document.data() as Map<String, dynamic>?;

    /*
    if (data != null) {
      data.forEach((key, value) {
        print('$key: $value');
      });
    }
     */
    //print(DateFormat("dd MMMM, yyyy hh:mm aa").format(DateTime.parse(time).toLocal()));
    //Sender messages - right side

    var like = false;
    try {
      //document.reference.update({"like": like});
      like = document["like"];
    } catch(e){
      document.reference.update({"like": like});
      print(e.toString());
    }
    if (document["idFrom"] == id) {
      return Container(
        //color: Colors.black,
        child: Padding(
          padding: const EdgeInsets.all(3.0),
          child: Row(
            children: <Widget>[
              document["type"] == 0
                  //Text Message
                  ? Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(10.0),
                          bottomLeft: Radius.circular(10.0),
                          bottomRight: Radius.circular(10.0)),
                        //border: Border.all(color: like ? Colors.pinkAccent : Colors.transparent, width: 2, )
                      gradient: new LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [Color(0xff81ecec), Color(0xfff7f1e3), Color(0xff7efff5)],
                      ),
                    ),
                    child: Material(
                        child: document["content"].length < 24
                            ? Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10.0, horizontal: 10.0),
                                child: GestureDetector(
                                  /*
                                  onDoubleTap: (){
                                    setState(() {
                                      //document.reference.update({"like": like});
                                    });
                                  },

                                   */
                                  onLongPress: () {
                                    Clipboard.setData(ClipboardData(
                                        text: document["content"].toString()));
                                    Fluttertoast.showToast(msg: "Copied");
                                  },
                                  child: Text(
                                    document["content"],
                                    style: const TextStyle(
                                        color: messageTextColor,
                                        fontWeight: FontWeight.w400,
                                        fontSize: 15),
                                  ),
                                ),
                              )
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                    Flexible(
                                      fit: FlexFit.loose,
                                      flex: 1,
                                      child: GestureDetector(
                                        onDoubleTap: (){
                                          /*
                                          setState(() {
                                            //document.reference.update({"like": like});
                                          });

                                           */
                                        },
                                        onLongPress: () {
                                          Clipboard.setData(ClipboardData(
                                              text:
                                                  document["content"].toString()));
                                          Fluttertoast.showToast(msg: "Copied");
                                        },
                                        child: Container(
                                          constraints:
                                              BoxConstraints(maxWidth: 250),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 10.0, horizontal: 10.0),
                                            child: Text(
                                              document["content"],
                                              style: const TextStyle(
                                                  color: messageTextColor,
                                                  fontWeight: FontWeight.w400,
                                                  fontSize: 15),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ]),
                        color: like ? Colors.transparent : subThemeColor,

                        shape: RoundedRectangleBorder(
                            borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(10.0),
                                bottomLeft: Radius.circular(10.0),
                                bottomRight: Radius.circular(10.0)),
                          side: BorderSide(color: like ? Colors.pinkAccent : Colors.transparent, width: 2, )
                        ),

                      //shadowColor: Colors.black,
                      ),
                  )
                  : document["type"] == 1
                      //Image Message
                      ? document["content"] != ""
                          ? Container(
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(context,
                                      MaterialPageRoute(builder: (context) {
                                    return FullPhoto(url: document["content"], darkMode: darkMode,);
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
                                      child: const CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                            subThemeColor),
                                      ),
                                      width: 200.0,
                                      height: 200.0,
                                      padding: const EdgeInsets.all(70.0),
                                      decoration: const BoxDecoration(
                                        color: Colors.grey,
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(10.0)),
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
                                      borderRadius: BorderRadius.circular(10.0),
                                      clipBehavior: Clip.hardEdge,
                                    ),
                                  ),
                                  borderRadius: BorderRadius.circular(10.0),
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
                style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 10.0,
                    fontWeight: FontWeight.bold),
              )
            ],
            mainAxisAlignment: MainAxisAlignment.end,
          ),
        ),
      );
    } else {
      //Receiver messages - left side
      return Container(
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Material(
                  //Display Receive Profile Img
                  child: CachedNetworkImage(
                    imageUrl: receiverProfileImg,
                    width: 35.0,
                    height: 35.0,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      child: const CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(subThemeColor),
                      ),
                      width: 35.0,
                      height: 35.0,
                      padding: const EdgeInsets.all(10.0),
                    ),
                  ),
                  borderRadius: const BorderRadius.all(Radius.circular(18.0)),
                  clipBehavior: Clip.hardEdge,
                ),
                //Display Message
                document["type"] == 0
                    //Text Message
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 7.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(10.0),
                                bottomLeft: Radius.circular(10.0),
                                bottomRight: Radius.circular(10.0)),
                            //border: Border.all(color: like ? Colors.pinkAccent : Colors.transparent, width: 2, )
                            gradient: new LinearGradient(

                              colors: [Color(0xfff8a5c2), Color(0xffffcccc), Color(0xfffab1a0)],
                            ),
                          ),
                          child: Material(
                            child: document["content"].length < 24
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10.0, horizontal: 10.0),
                                    child: GestureDetector(
                                      onDoubleTap: (){
                                        setState(() {
                                          like = !document["like"];
                                          document.reference.update({"like": like});
                                        });
                                      },
                                      onLongPress: () {
                                        Clipboard.setData(ClipboardData(
                                            text:
                                                document["content"].toString()));
                                        Fluttertoast.showToast(msg: "Copied");
                                      },
                                      child: Text(
                                        document["content"],
                                        style: const TextStyle(
                                            color: messageTextColor,
                                            fontWeight: FontWeight.w400,
                                            fontSize: 15),
                                      ),
                                    ),
                                  )
                                : Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                        Flexible(
                                          flex: 1,
                                          fit: FlexFit.loose,
                                          child: GestureDetector(
                                            onDoubleTap: (){
                                              setState(() {
                                                like = !document["like"];
                                                document.reference.update({"like": like});
                                              });
                                            },
                                            onLongPress: () {
                                              Clipboard.setData(ClipboardData(
                                                  text: document["content"]
                                                      .toString()));
                                              Fluttertoast.showToast(
                                                  msg: "Copied");
                                            },
                                            child: Container(
                                              constraints:
                                                  BoxConstraints(maxWidth: 250),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 10.0,
                                                        horizontal: 10.0),
                                                child: Text(
                                                  document["content"],
                                                  style: const TextStyle(
                                                      color: messageTextColor,
                                                      fontWeight: FontWeight.w400,
                                                      fontSize: 15),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ]),

                            //color: subBackgroundColor,
                            color: like ? Colors.transparent : subBackgroundColor,

                            shape: RoundedRectangleBorder(
                                borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(10.0),
                                    bottomLeft: Radius.circular(10.0),
                                    bottomRight: Radius.circular(10.0)),
                                side: BorderSide(color: like ? Colors.pinkAccent : Colors.transparent, width: 2, )
                            ),
                          ),

                        ),
                      )
                    : document["type"] == 1
                        //Image Message
                        ? Container(
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(context,
                                    MaterialPageRoute(builder: (context) {
                                  return FullPhoto(url: document["content"], darkMode: darkMode,);
                                }));
                              },
                              child: Material(
                                child: CachedNetworkImage(
                                  imageUrl: document["content"].toString(),
                                  width: 200.0,
                                  height: 200.0,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    child: const CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          subThemeColor),
                                    ),
                                    width: 200.0,
                                    height: 200.0,
                                    padding: const EdgeInsets.all(70.0),
                                    decoration: const BoxDecoration(
                                      color: Colors.grey,
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(10.0)),
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
                                    borderRadius: BorderRadius.circular(10.0),
                                    clipBehavior: Clip.hardEdge,
                                  ),
                                ),
                                borderRadius: BorderRadius.circular(10.0),
                                clipBehavior: Clip.hardEdge,
                              ),
                            ),
                            margin: const EdgeInsets.only(left: 7.0),
                          ) //Emoji
                        : Container(
                            child: Image.network(
                              document["content"],
                              width: 100.0,
                              height: 100.0,
                              fit: BoxFit.cover,
                            ),
                            margin: const EdgeInsets.only(left: 7.0),
                          )
              ],
            ),
            isLastReceiveMessage(index)
                ? Center(
                    child: Container(
                      child: Text(
                        //dd MMMM, yyyy - kk:mm:aa
                        DateFormat("dd MMMM, yyyy hh:mm aa")
                            .format(DateTime.parse(document["time"]).toLocal()),
                        style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12.0,
                            fontStyle: FontStyle.italic),
                      ),
                      margin: const EdgeInsets.only(top: 10.0, bottom: 10.0),
                    ),
                  )
                : Container()
          ],
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
        margin: const EdgeInsets.only(bottom: 3.0, top: 3.0),
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
        color: darkMode ? Colors.black : Colors.white,
      ),
      padding: const EdgeInsets.all(5.0),
      height: 220.0,
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              TextButton(
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
              TextButton(
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
              TextButton(
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
              TextButton(
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
              TextButton(
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
              TextButton(
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
              TextButton(
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
              TextButton(
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
              TextButton(
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
              TextButton(
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
              TextButton(
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
              TextButton(
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

  createListMessage() {
    //Set message as read
    return Flexible(
        child: chatID == ""
            ? const Center(
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(subThemeColor),
                ),
              )
            //Read 15 current time-communication transactions
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
                    return const Center(
                      child: const CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(subThemeColor),
                      ),
                    );
                  } else {
                    //Write to chat communication that current had read
                    FirebaseFirestore.instance
                        .collection("messages")
                        .doc(chatID)
                        .update({"user $id read": true});
                    listMessage = snapshot.data!.docs;
                    return Container(
                      //color: darkMode ? Colors.black : backgroundColor,
                      child: ListView.builder(
                        //itemExtent: 20,
                        padding: EdgeInsets.all(10.0),
                        itemBuilder: (context, index) {
                          if (index == listMessage.length) {
                            return CupertinoActivityIndicator();
                          }
                          //DocumentSnapshot document = snapshot.data!.docs[index];

                          return createItem(index, snapshot.data!.docs[index]);
                        },
                        itemCount: snapshot.data!.docs.length,
                        reverse: true,
                        controller: chatListScrollController,

                      ),
                    );
                  }
                },
              ));
  }

  createInput() {
    return Container(
      child: Padding(
        padding: EdgeInsets.only(top: 5),
        child: Row(
          children: <Widget>[
            //Image Picker Button
            Material(
              child: Container(
                child: IconButton(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  iconSize: 30,
                  padding: EdgeInsets.all(0.0),
                  icon: const Icon(Icons.photo_camera),
                  color: darkMode ? Colors.white : Colors.black, //buttonColor,
                  onPressed: () {
                    getImage(ImageSource.camera);
                  },
                ),
              ),
              color: darkMode ? Colors.black : backgroundColor,
            ),
            Material(
              child: Container(
                //margin: const EdgeInsets.symmetric(horizontal: 1.0),
                child: IconButton(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  iconSize: 30,
                  padding: EdgeInsets.all(0.0),
                  icon: const Icon(Icons.photo),
                  color: darkMode ? Colors.white : Colors.black, //buttonColor,
                  onPressed: () {
                    getImage(ImageSource.gallery);
                  },
                ),
              ),
              color: darkMode ? Colors.black : backgroundColor,
            ),
            //Emoji Button
            Material(
              child: Container(
                //margin: const EdgeInsets.symmetric(horizontal: 1.0),
                child: IconButton(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  iconSize: 30,
                  padding: EdgeInsets.all(0.0),
                  icon: Icon(Icons.emoji_emotions),
                  color: darkMode ? Colors.white : Colors.black, //buttonColor,
                  onPressed: () {
                    getSticker();
                  },
                ),
              ),
              color: darkMode ? Colors.black : backgroundColor,
            ),
            //Text Message Field
            Flexible(
                child: Container(
                  //padding: EdgeInsets.only(top: 5.0),
              color: darkMode ? Colors.black : backgroundColor,
              child: TextField(
                keyboardType: TextInputType.multiline,
                maxLines: null,
                style: TextStyle(
                  color: darkMode ? Colors.white : messageTextColor,
                  fontSize: 15.0,
                  fontWeight: FontWeight.w400
                ),
                controller: textEditingController,
                decoration: InputDecoration(
                    contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                    isDense: true,
                    border: OutlineInputBorder(),
                    hintText: "Type Message",
                    hintStyle: TextStyle(color: darkMode ? Colors.white70 : Colors.grey),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(25.0), borderSide: BorderSide(width: 1, color: darkMode ? Colors.white : Colors.black)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(25.0), borderSide: BorderSide(width: 1, color: darkMode ? Colors.white : Colors.black)),
                ),
                focusNode: focusNode,
              ),
            )),
            //Send Message Button
            Material(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8.0),
                child: ElevatedButton(
                  onPressed: () {
                    onSendMessage(textEditingController.text, 0);
                  },
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    //padding: EdgeInsets.all(),
                    backgroundColor: buttonColor,
                  ),
                  child: Icon(
                    Icons.send,
                    color: darkMode ? Colors.white : Colors.black,
                    size: 25,
                  ),
                ),
              ),
              color: darkMode ? Colors.black : backgroundColor,
            ),
          ],
        ),
      ),
      width: double.infinity,
      height: 55.0,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: darkMode ? Colors.white70 : Colors.black,
            width: 0.5,
          ),
        ),
        color: darkMode ? Colors.black : backgroundColor,
      ),
    );
  }
}
