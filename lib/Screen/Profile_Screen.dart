import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ume_talk/Models/themeColor.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ProfileChatWithInfo extends StatelessWidget {
  final String id;
  final String receiverId;
  final String name;
  final String photoUrl;
  final String about;
  const ProfileChatWithInfo(
      {Key? key,
      required this.id,
      required this.receiverId,
      required this.name,
      required this.photoUrl,
      required this.about})
      : super(key: key);

  void showAlertDialog(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text('Report User'),
        content: const Text('You can report this user if you think it goes against our policy. We won\'t notify the account that you submitted this report.'),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              report(context);
            },
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  void report(BuildContext context) async{
    final QuerySnapshot resultQuery = await FirebaseFirestore.instance
        .collection("report")
        .where(receiverId)
        .get();
    final List<DocumentSnapshot> documentSnapshots = resultQuery.docs;
    //if(documentSnapshots.length == 0){FirebaseFirestore.instance.collection("report").doc(id).set({});
    if(documentSnapshots.length == 0){
      FirebaseFirestore.instance.collection("report").doc(receiverId).set({
        "$id" : 1
      });
    }else{
      try{
        FirebaseFirestore.instance.collection("report").doc(receiverId).update({
          "$id" : documentSnapshots[0][id] + 1
        });
      }on Error catch(e){
        FirebaseFirestore.instance.collection("report").doc(receiverId).set({
          "$id" : 1});
      }
    }
    Navigator.pop(context);
    Fluttertoast.showToast(
        toastLength: Toast.LENGTH_LONG,
        msg: "Thank you for submitted your report");
  }

  @override
  Widget build(BuildContext context) {
    var deviceWidth = MediaQuery.of(context).size.width;
    return Container(
      decoration: const BoxDecoration(
        gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [themeColor, subThemeColor]),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.black),
          backgroundColor: Colors.transparent,
          elevation: 0.0,
        ),
        body: Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            //mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Center(
                child: Material(
                  borderRadius: BorderRadius.all(Radius.circular(360.0)),
                  clipBehavior: Clip.hardEdge,
                  child: Image.network(
                    photoUrl,
                    width: deviceWidth / 1.5,
                    height: deviceWidth / 1.5,
                    fit: BoxFit.cover,
                  ), //Add Loading builder
                ),
              ),
              const SizedBox(
                height: 50.0,
              ),
              Text(
                name,
                style: const TextStyle(
                    color: Colors.black,
                    fontSize: 30.0,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(
                height: 20.0,
              ),
              Text(
                about,
                style: const TextStyle(
                    color: Colors.black,
                    fontSize: 20.0,
                    fontStyle: FontStyle.italic),
              ),
              SizedBox(height: 100.0,),
              ElevatedButton(
                  onPressed: (){
                    showAlertDialog(context);
                  },
                  style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      primary: Colors.redAccent,
                      fixedSize: const Size(60,60)
                  ),
                  child: const Icon(Icons.report_rounded)),
              SizedBox(height: 10.0,),
              Text("Report")
            ],
          ),
        ),
      ),
    );
  }
}
