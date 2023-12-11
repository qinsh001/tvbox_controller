import 'package:flutter/material.dart';

class AppUtils{
  static void showSnackBar(BuildContext context,String msg)  {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
    ));
  }
}