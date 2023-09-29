import 'dart:async';
import 'dart:io';
import 'dart:developer' as developer;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:vocal_message/src/audio_list.dart';
import 'package:vocal_message/src/audio_state.dart';
import 'package:vocal_message/src/file_status.dart';
import 'package:vocal_message/src/globals.dart';
import 'package:vocal_message/src/recorder_mobile_ui/record_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'recorder_desktop_ui/desktop_frame.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  static const route = '/home';

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;

  bool isDeviceConnected = false;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    initConnectivity();

    _connectivitySubscription = _connectivity.onConnectivityChanged
        .listen((ConnectivityResult result) async {
      final temp = await isInternetAvailable(result);
      setState(() => isDeviceConnected = temp);
    });
  }

  @override
  void dispose() {
    controller.dispose();
    _connectivitySubscription.cancel();
    super.dispose();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initConnectivity() async {
    late ConnectivityResult result;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      result = await _connectivity.checkConnectivity();
    } on PlatformException catch (e) {
      developer.log('Couldn\'t check connectivity status', error: e);
      return;
    }

    // better discard the reply
    // if the widget is removed from the tree while the async platform message is in flight
    if (!mounted) {
      return Future.value(null);
    }

    final temp = await isInternetAvailable(result);
    setState(() => isDeviceConnected = temp);
    return;
  }

  Future<bool> isInternetAvailable(ConnectivityResult result) async {
    if (result == ConnectivityResult.none) {
      return false;
    } else {
      return await InternetConnectionChecker().hasConnection;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Audio Chat"),
        actions: [
          IconButton(
              onPressed: () {
                final dummy = TheirFileStatus(
                    SyncStatus.remoteNotSynced, 'remoteNotSynced');
                AudioState.allAudioFiles.theirFiles.add(dummy);
                Globals.audioListKey.currentState!
                    .insertItem(AudioState.allAudioFiles.all.length - 1);
              },
              icon: const Icon(Icons.ac_unit))
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(Globals.defaultPadding),
        child: Column(
          children: [
            Expanded(child: AudioList(isDeviceConnected)),
            Container(
              color: Theme.of(context).primaryColor.withOpacity(0.8),
              height: 8,
            ),
            Padding(
              padding: const EdgeInsets.all(22.0),
              child: (!kIsWeb && (Platform.isAndroid || Platform.isIOS))
                  ? RecorderMobileView(
                      controller: controller,
                      azureFolderFullPath: '/audio-test/jimmy_jo/uploads',
                    )
                  : const RecorderDesktopFrame(
                      azureFolderFullPath: '/audio-test/jimmy_jo/uploads',
                    ),
            ),
            const SizedBox(height: 12)
          ],
        ),
      ),
    );
  }
}
