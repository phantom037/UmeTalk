import 'package:flutter/material.dart';
import 'package:ume_talk/Models/themeColor.dart';

class ProfileChatWithInfo extends StatelessWidget {
  final String name;
  final String photoUrl;
  final String about;
  const ProfileChatWithInfo(
      {Key? key,
      required this.name,
      required this.photoUrl,
      required this.about})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var deviceWidth = MediaQuery.of(context).size.width;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [themeColor, subThemeColor]),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
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
              SizedBox(
                height: 50.0,
              ),
              Text(
                name,
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 30.0,
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(
                height: 20.0,
              ),
              Text(
                about,
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 20.0,
                    fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
