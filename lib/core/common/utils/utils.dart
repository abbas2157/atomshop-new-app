import 'package:flutter/material.dart';

Widget logo() {
  return Image.asset('assets/images/logo.png', width: 200, height: 200);
}

Widget navLogo({double? height, double? width}) {
  return Image.asset(
    'assets/images/nav-logo.png',
    width: width ?? 150,
    height: height ?? 150,
  );
}
