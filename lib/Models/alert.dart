import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Widget showAlert(errorMessage) {
  if (errorMessage != null) {
    return Container(
      color: Colors.transparent,
      width: double.infinity,
      padding: EdgeInsets.all(8.0),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child:
                  errorMessage == "" ? Container() : Icon(Icons.error_outline),
            ),

            Expanded(
              child: Text(
                errorMessage,
                style: TextStyle(
                  color: Colors.yellowAccent,
                  fontSize: 12.0,
                ),
              ),
            ),
            //Expanded
          ]),
    ); //Container
  }
  return SizedBox(
    height: 0,
  );
}
