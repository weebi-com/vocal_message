import 'package:flutter/material.dart';
import 'package:vocal_message/home.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  static const route = '/home';

  @override
  Widget build(BuildContext context) {
    return const VocalMessagesAndRecorderView("Voc'up");
  }
}
