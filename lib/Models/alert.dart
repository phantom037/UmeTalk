import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Widget showAlert(errorMessage) {
  if (errorMessage != null) {
    return Container(
      color: Colors.transparent,
      width: double.infinity,
      padding: const EdgeInsets.all(8.0),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: errorMessage == ""
                  ? Container()
                  : Icon(
                      Icons.error_outline,
                      color: Colors.redAccent,
                    ),
            ),

            Expanded(
              child: Text(
                errorMessage,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 15.0,
                ),
              ),
            ),
            //Expanded
          ]),
    ); //Container
  }
  return const SizedBox(
    height: 0,
  );
}
