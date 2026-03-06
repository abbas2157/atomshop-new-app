import 'package:flutter/material.dart';

class SnackbarService {
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  // Singleton pattern
  static final SnackbarService _instance = SnackbarService._internal();

  factory SnackbarService() {
    return _instance;
  }

  SnackbarService._internal();

  // remove current SnackBar
  void hideCurrentSnackBar() {
    scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
  }

  // Show an error SnackBar
  void showErrorSnackBar(String message) {
    hideCurrentSnackBar();
    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(Icons.error, color: Colors.white),
          SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );

    scaffoldMessengerKey.currentState?.showSnackBar(snackBar);
  }

  // Show a success SnackBar
  void showSuccessSnackBar(String message) {
    hideCurrentSnackBar();
    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.white),
          SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );

    scaffoldMessengerKey.currentState?.showSnackBar(snackBar);
  }

  // Show an info SnackBar
  void showInfoSnackBar(String message) {
    hideCurrentSnackBar();
    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(Icons.info, color: Colors.white),
          SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: Colors.blue,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );

    scaffoldMessengerKey.currentState?.showSnackBar(snackBar);
  }
}
