import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:dio/dio.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:ume_talk/Models/themeColor.dart';
import 'package:ume_talk/Widgets/Progress_Widget.dart';
import 'package:fluttertoast/fluttertoast.dart';

class FullPhoto extends StatelessWidget {
  final String url;
  final bool darkMode;
  FullPhoto({Key? key, required this.url, required this.darkMode}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: themeColor,
        iconTheme: IconThemeData(color: Colors.black),
        title: Container(
          alignment: Alignment.topRight,
          child: MaterialButton(
            child: Icon(Icons.download_rounded, color: Colors.black),
            onPressed: () {
              _save(url);
            },
          ),
        ),
      ),
      body: FullPhotoScreen(url: url, darkMode: darkMode,),
    );
  }

  _save(String url) async {
    try {
      var response = await Dio()
          .get(url, options: Options(responseType: ResponseType.bytes));
      final result = await ImageGallerySaver.saveImage(
        Uint8List.fromList(response.data),
      );
      Fluttertoast.showToast(msg: "Saved");
    } on Exception catch (error) {
      Fluttertoast.showToast(msg: "Unable to download image");
    }
  }
}

class FullPhotoScreen extends StatefulWidget {
  final String url;
  final bool darkMode;
  FullPhotoScreen({Key? key, required this.url, required this.darkMode}) : super(key: key);
  @override
  State createState() => FullPhotoScreenState(url: url, darkMode: darkMode);
}

class FullPhotoScreenState extends State<FullPhotoScreen> {
  final String url;
  final bool darkMode;
  FullPhotoScreenState({Key? key, required this.url, required this.darkMode});
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: darkMode ? Colors.black : backgroundColor,
      child: PhotoView(
        backgroundDecoration: BoxDecoration(color: darkMode ? Colors.black : backgroundColor),
        loadingBuilder: (context, progress) => Center(
          child: Container(
            width: 200.0,
            height: 50.0,
            child: linearProgress(),
          ),
        ),
        imageProvider: NetworkImage(url),
      ),
    );
  }
}
