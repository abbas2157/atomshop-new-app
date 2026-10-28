import 'package:flutter/material.dart';

/// App-wide messenger, so code outside a screen (the session, push taps)
/// can show a short message. Set as MaterialApp.scaffoldMessengerKey.
final atomMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Short confirmation or problem message at the bottom of the screen.
void atomToast(String message) {
  final messenger = atomMessengerKey.currentState;
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
