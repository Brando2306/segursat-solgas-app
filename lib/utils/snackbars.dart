import 'package:flutter/material.dart';

class Snackbars {
  static GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static showSnackbar(String message) {
    final snackBar = SnackBar(
      content: Text(message,
          maxLines: 3,
          textAlign: TextAlign.left,
          style: TextStyle(fontSize: 13)),
    );
    messengerKey.currentState!.showSnackBar(snackBar);
  }

  static showSnackbarSuccess(String message) {
    final snackBar = SnackBar(
      backgroundColor: Colors.green.withOpacity(0.9),
      content: Text(message,
          maxLines: 3,
          textAlign: TextAlign.left,
          style: TextStyle(fontSize: 13)),
    );
    messengerKey.currentState!.showSnackBar(snackBar);
  }

  static showSnackbarError(String message) {
    final snackBar = SnackBar(
      backgroundColor: Colors.red.withOpacity(0.9),
      content: Text(message,
          maxLines: 3,
          textAlign: TextAlign.left,
          style: TextStyle(fontSize: 13)),
    );
    messengerKey.currentState!.showSnackBar(snackBar);
  }
}
