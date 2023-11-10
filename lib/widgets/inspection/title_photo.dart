import 'package:flutter/cupertino.dart';
import 'package:safe_driving_app/utils/style.dart';

Container titlePhoto(String text) {
  return Container(
    padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: CustomColors.secundary),
    ),
  );
}
