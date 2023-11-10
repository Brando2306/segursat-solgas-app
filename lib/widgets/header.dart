import 'package:flutter/material.dart';

AppBar header(String text) {
  return AppBar(
    title: Text(text,
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        )),
    centerTitle: true,
    elevation: 0.0,
    backgroundColor: Colors.white,
    leading: Container(),
    actions: [],
  );
}

AppBar headerV2(String text, Widget leading) {
  return AppBar(
      title: Text(text,
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          )),
      centerTitle: true,
      elevation: 0.0,
      backgroundColor: Colors.white,
      leading: leading);
}
