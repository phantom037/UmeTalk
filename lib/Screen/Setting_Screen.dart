import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ume_talk/Models/fcm_notification.dart';
import 'package:ume_talk/Models/notification.dart';
import 'package:ume_talk/Models/themeColor.dart';
import 'package:ume_talk/Widgets/Progress_Widget.dart';
import 'package:ume_talk/main.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class Setting extends StatelessWidget {
  void initState() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.bottom]); // to hide only bottom bar
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: themeColor,
          iconTheme: IconThemeData(
            color: Colors.black,
          ),
          title: Text(
            "Setting",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 30.0,
            ),
          ),
          centerTitle: true,
        ),
        body: SettingsScreen());
  }
}

class SettingsScreen extends StatefulWidget {
  @override
  State createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  late SharedPreferences preference;
  String id = "";
  String name = "";
  String about = "";
  String photoUrl = "";
  TextEditingController nameTextEditingController = TextEditingController();
  TextEditingController aboutTextEditingController = TextEditingController();
  File? profileImage;
  bool showSpin = false;
  final FocusNode nameFocusNode = FocusNode();
  final FocusNode aboutMeFocusNode = FocusNode();
  final GoogleSignIn googleSignIn = GoogleSignIn();

  ///FCM Notification
  /*
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final CollectionReference _tokensDB =
      FirebaseFirestore.instance.collection('user');
  final FCMNotificationService _fcmNotificationService =
      FCMNotificationService();
  late String deviceToken;

   */
  @override
  void initState() {
    super.initState();
    readDataFromLocal();

    ///Notification
    //NotificationAPI.init();
    //listenNotifications();
    ///FCM Notification
    //_fcmNotificationService.subscribeToTopic(topic: 'NEWS');
    //load();
  }

  ///FCM Notification
  /*
  Future<void> load() async {
    //Request permission from user.
    if (Platform.isIOS) {
      _fcm.requestPermission();
    }

    //Fetch the fcm token for this device.
    String? token = await _fcm.getToken();

    //Validate that it's not null.
    assert(token != null);

    //Update fcm token for this device in firebase.
    DocumentReference docRef = _tokensDB.doc(id);
    docRef.set({'token': token});

    //Fetch the fcm token for the other device.
    DocumentSnapshot docSnapshot = await _tokensDB.doc(id).get();
    deviceToken = docSnapshot['token'];
  }
   */

  /*
  ///Notification
  void listenNotifications() =>
      NotificationAPI.onNotification.stream.listen(onClickedNotification);

  void onClickedNotification(String? payload) =>
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => TestScreen(payload: payload),
      ));

  ///End Notification

   */
  void readDataFromLocal() async {
    preference = await SharedPreferences.getInstance();
    id = preference.getString("id").toString();
    name = preference.getString("name").toString() == "null"
        ? "User ${id.substring(0, 9)}"
        : preference.getString("name").toString();
    about = preference.getString("about").toString();
    photoUrl = preference.getString("photoUrl").toString() == "null"
        ? "https://dlmocha.com/app/Ume-Talk/userDefaultAvatar.jpeg"
        : preference.getString("photoUrl").toString();

    nameTextEditingController = TextEditingController(text: name);
    aboutTextEditingController = TextEditingController(text: about);
    setState(() {
      showSpin = false;
    });
  }

  Future getImage(ImageSource sourcePicked) async {
    try {
      final ImagePicker _picker = ImagePicker();
      // Pick an image
      var image = await _picker.pickImage(source: sourcePicked);
      if (image != null) {
        setState(() {
          showSpin = true;
          //profileImage = image as File;
          final imagePicked = File(image.path);
          profileImage = imagePicked;
          uploadImageToFireStore();
          showSpin = false;
        });
      }
    } on PlatformException catch (e) {
      print("Failed to pick image");
    }
  }

  void updateData() {
    String convert = name.toLowerCase().replaceAll(' ', '');
    var arraySearchID = List.filled(convert.length, "");
    for (int i = 0; i < convert.length; i++) {
      arraySearchID[i] = convert.substring(0, i + 1).toString();
    }
    print("Print from update");
    for (int i = 0; i < convert.length; i++) {
      print("Index $i ${arraySearchID[i]}");
    }

    nameFocusNode.unfocus();
    aboutMeFocusNode.unfocus();
    FirebaseFirestore.instance.collection("user").doc(id).update({
      "photoUrl": photoUrl,
      "about": about,
      "name": name,
      "searchID": arraySearchID,
      //name.toLowerCase().replaceAll(' ', ''),
    }).then((data) async {
      await preference.setString("photoUrl", photoUrl);
      await preference.setString("about", about);
      await preference.setString("name", name);
    });
    Fluttertoast.showToast(msg: "Update Successfully");
    setState(() {
      showSpin = false;
    });
  }

  Future uploadImageToFireStore() async {
    String fileNameID = id;
    FirebaseStorage storage = FirebaseStorage.instance;
    Reference ref = storage.ref().child(fileNameID);
    UploadTask uploadTask = ref.putFile(profileImage!);
    uploadTask.then((res) {
      res.ref.getDownloadURL().then((newProfileImage) {
        photoUrl = newProfileImage;
        FirebaseFirestore.instance.collection("user").doc(id).update({
          "photoUrl": photoUrl,
          "about": about,
          "name": name,
          //"searchID": name.toLowerCase().replaceAll(' ', ''),
        }).then((data) async {
          await preference.setString("photoUrl", photoUrl);
        });
      });
    }).catchError((error) {
      Fluttertoast.showToast(msg: error);
    });
    setState(() {
      showSpin = false;
    });
  }

  Future logoutUser() async {
    await FirebaseAuth.instance.signOut();
    await googleSignIn.disconnect();
    await googleSignIn.signOut();
    setState(() {
      showSpin = false;
    });
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) {
      return MyApp();
    }), (Route<dynamic> route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            ///Profile Image
            Container(
              child: Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: <Widget>[
                    (profileImage == null)
                        ? (photoUrl != "")
                            ? Material(
                                //display already existing - old image file
                                child: CachedNetworkImage(
                                  placeholder: (context, url) => Container(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.0,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.lightBlueAccent),
                                    ),
                                    width: 200.0,
                                    height: 200.0,
                                    padding: EdgeInsets.all(20.0),
                                  ),
                                  imageUrl: photoUrl,
                                  width: 200.0,
                                  height: 200.0,
                                  fit: BoxFit.cover,
                                ),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(125.0)),
                                clipBehavior: Clip.hardEdge,
                              )
                            : Icon(
                                Icons.account_circle,
                                size: 90.0,
                                color: Colors.grey,
                              )
                        : Material(
                            //display the new updated image here
                            child: Image.file(
                              profileImage!,
                              width: 200.0,
                              height: 200.0,
                              fit: BoxFit.cover,
                            ),
                            borderRadius:
                                BorderRadius.all(Radius.circular(125.0)),
                            clipBehavior: Clip.hardEdge,
                          ),
                    Container(
                      decoration: BoxDecoration(color: Colors.transparent),
                      width: 50,
                      height: 50,
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: IconButton(
                          icon: Icon(
                            Icons.add_circle_outline,
                            size: 50.0,
                            color: Colors.black,
                          ),
                          onPressed: () => getImage(ImageSource.gallery),
                          padding: EdgeInsets.all(0.0),
                          //splashColor: Colors.transparent,
                          //highlightColor: Colors.black54,
                          //iconSize: 10.0,
                        ),
                      ),
                    ),

                    /*
                      (profileImage == null)
                          ? (photoUrl != "")
                              ? Material(
                                  //Display Exiting Image
                                  child: CachedNetworkImage(
                                    imageUrl: photoUrl,
                                    width: 200.0,
                                    height: 200.0,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) {
                                      return Container(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.0,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.lightGreenAccent),
                                        ),
                                        width: 200.0,
                                        height: 200.0,
                                        padding: EdgeInsets.all(20.0),
                                      );
                                    },
                                  ),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(125.0)),
                                  clipBehavior: Clip.hardEdge,
                                )
                              : Icon(
                                  Icons.account_circle,
                                  size: 90.0,
                                  color: Colors.grey,
                                )
                          : Material(
                              //Display new Image here
                              child: Image.file(
                                profileImage!,
                                width: 200.0,
                                height: 200.0,
                                fit: BoxFit.cover,
                              ),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(125.0)),
                              clipBehavior: Clip.hardEdge,
                            ),


                    CircleAvatar(
                      radius: 30.0,
                      backgroundImage: NetworkImage(
                          "https://media.istockphoto.com/vectors/default-profile-picture-avatar-photo-placeholder-vector-illustration-vector-id1214428300?k=20&m=1214428300&s=170667a&w=0&h=NPyJe8rXdOnLZDSSCdLvLWOtIeC9HjbWFIx8wg5nIks="),
                    ),
                    Align(
                      //alignment: Alignment.bottomRight,
                      child: Container(
                        width: 100.0,
                        height: 100.0,
                        decoration: BoxDecoration(
                            color: Colors.amber, shape: BoxShape.circle),
                        child: IconButton(
                          icon: Icon(
                            Icons.add_circle_outline,
                            size: 30.0,
                            color: Colors.white54.withOpacity(0.3),
                          ),
                          onPressed: () => getImage(ImageSource.gallery),
                          padding: EdgeInsets.all(0.0),
                          splashColor: Colors.transparent,
                          highlightColor: Colors.grey,
                          iconSize: 30.0,
                        ),
                      ),
                    ),
                    */
                  ],
                ),
              ),
              //alignment: Alignment.bottomRight,
              width: double.infinity,
              margin: EdgeInsets.all(20.0),
            ),
            /*
            Container(
                color: Colors.transparent,
                height: 30.0,
                width: 150.0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    IconButton(
                      icon: Icon(
                        Icons.camera_alt_outlined,
                        size: 30.0,
                        color: Colors.black,
                      ),
                      onPressed: () => getImage(ImageSource.camera),
                      padding: EdgeInsets.all(0.0),
                      splashColor: Colors.blueGrey,
                      highlightColor: Colors.grey,
                      iconSize: 50.0,
                    ),
                    SizedBox(
                      width: 50.0,
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.photo_album_outlined,
                        size: 30.0,
                        color: Colors.black,
                      ),
                      onPressed: () => getImage(ImageSource.gallery),
                      padding: EdgeInsets.all(0.0),
                      splashColor: Colors.blueGrey,
                      highlightColor: Colors.grey,
                      iconSize: 50.0,
                    ),
                  ],
                )),
             */
            SizedBox(
              height: 20.0,
            ),
            Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(1.0),
                  child: showSpin ? circularProgress() : Container(),
                ),
                Container(
                  //Display User Name
                  child: Theme(
                    data:
                        Theme.of(context).copyWith(primaryColor: Colors.black),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Name",
                        contentPadding: EdgeInsets.all(3.0),
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                      controller: nameTextEditingController,
                      onChanged: (value) {
                        name = value;
                      },
                      focusNode: nameFocusNode,
                    ),
                  ),

                  margin: EdgeInsets.only(left: 30.0, right: 30.0),
                ),
                Container(
                  //Display About Me
                  child: Theme(
                    data:
                        Theme.of(context).copyWith(primaryColor: Colors.black),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "About Me",
                        contentPadding: EdgeInsets.all(3.0),
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                      controller: aboutTextEditingController,
                      onChanged: (value) {
                        about = value;
                      },
                      focusNode: aboutMeFocusNode,
                    ),
                  ),
                  margin: EdgeInsets.only(left: 30.0, right: 30.0),
                ),
                SizedBox(
                  height: 30.0,
                ),
                Material(
                  color: Colors.greenAccent,
                  borderRadius: BorderRadius.all(Radius.circular(30.0)),
                  elevation: 5.0,
                  child: Container(
                    width: 300.0,
                    child: MaterialButton(
                      child: Text(
                        "Update",
                        style: TextStyle(color: Colors.black, fontSize: 16.0),
                      ),
                      textColor: Colors.white,
                      padding: EdgeInsets.fromLTRB(30.0, 10.0, 30.0, 10.0),
                      onPressed: updateData,
                    ),
                    margin: EdgeInsets.only(bottom: 1.0),
                  ),
                ),
                SizedBox(
                  height: 30.0,
                ),
                Material(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.all(Radius.circular(30.0)),
                  elevation: 5.0,
                  child: Container(
                    width: 300.0,
                    child: MaterialButton(
                      child: Text(
                        "Log out",
                        style: TextStyle(color: Colors.black, fontSize: 16.0),
                      ),
                      textColor: Colors.white,
                      padding: EdgeInsets.fromLTRB(30.0, 10.0, 30.0, 10.0),
                      onPressed: logoutUser,
                    ),
                    margin: EdgeInsets.only(bottom: 1.0),
                  ),
                ),
              ],
              crossAxisAlignment: CrossAxisAlignment.center,
            ),
          ],
        ), //Column
        padding: EdgeInsets.only(left: 15.0, right: 15.0),
      ),
    );
  }
}
