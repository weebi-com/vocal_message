// ignore: file_names
import 'dart:async';
import 'dart:io';
import 'dart:developer' as developer;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:vocal_message/src/aa_android_storage.dart';
import 'package:vocal_message/src/b_record_frame_permission.dart';
import 'package:vocal_message/src/messages/audio_list.dart';
import 'package:vocal_message/src/messages/audio_state.dart';
import 'package:vocal_message/src/globals.dart';
import 'package:flutter/material.dart';

class VocalMessagesAndRecorderView extends StatefulWidget {
  final String title;
  const VocalMessagesAndRecorderView(this.title, {Key? key}) : super(key: key);

  @override
  State<VocalMessagesAndRecorderView> createState() =>
      _VocalMessagesAndRecorderViewState();
}

class _VocalMessagesAndRecorderViewState
    extends State<VocalMessagesAndRecorderView>
    with SingleTickerProviderStateMixin {
  bool isDeviceConnected = false;
  bool isSyncing = false;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    initConnectivity();

    _connectivitySubscription = _connectivity.onConnectivityChanged
        .listen((ConnectivityResult result) async {
      final temp = await isInternetAvailable(result);
      setState(() => isDeviceConnected = temp);
    });
  }

  @override
  void dispose() {
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
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: isDeviceConnected
                ? isSyncing
                    ? const Icon(Icons.cloud_sync_sharp)
                    : const Icon(Icons.sync)
                : const Icon(Icons.signal_wifi_connected_no_internet_4),
            onPressed: isDeviceConnected
                ? () async {
                    setState(() => isSyncing = true);
                    await getLocalAudioFetchFilesAndSetStatus(isDeviceConnected)
                        .then(
                      (value) => setState(() => isSyncing = false),
                    );
                  }
                : null,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(Globals.defaultPadding),
        child: Column(
          children: [
            Expanded(
              child: AudioList(
                isDeviceConnected,
                () async =>
                    getLocalAudioFetchFilesAndSetStatus(isDeviceConnected),
              ),
            ),
            Container(
              color: Theme.of(context).primaryColor.withOpacity(0.8),
              height: 8,
            ),
            const SizedBox(height: 12),
            if (Platform.isAndroid)
              const AndroidExtStorageWidget(RecorderFrame())
            else
              const RecorderFrame(),
          ],
        ),
      ),
    );
  }
}
