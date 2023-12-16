import 'package:flutter/material.dart';
import 'package:vocal_message/home.dart';
import 'package:vocal_message/logic.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  static const route = '/home';

  @override
  Widget build(BuildContext context) {
    if (Globals.config.rootPath.isEmpty) {
      return const Center(child: Text('Globals.azureRootPath is empty'));
    }
    if (Globals.documentPath.isEmpty) {
      return const Text('Globals.documentPath is empty');
    }
    return const PermissionView("Voc'up");
  }
}
