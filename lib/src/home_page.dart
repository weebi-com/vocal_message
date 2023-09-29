import 'dart:io';

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

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
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
            const Expanded(child: AudioList(false)),
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
