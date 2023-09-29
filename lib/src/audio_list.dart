import 'package:vocal_message/src/audio_state.dart';
import 'package:vocal_message/src/globals.dart';
import 'package:vocal_message/src/widgets/audio_bubble.dart';
import 'package:flutter/material.dart';

class AudioList extends StatelessWidget {
  final bool isConnected;
  const AudioList(this.isConnected, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    debugPrint(
        'AudioState.files.length ${AudioState.allAudioFiles.all.length}');

    return FutureBuilder<AllAudioFiles>(
        future: getLocalAudioFetchFilesAndSetStatus(
            '/audio-test/jimmy_jo', isConnected),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const ColoredBox(color: Colors.black);
          } else if (snap.hasError) {
            debugPrint('${snap.error}');
            return ColoredBox(
                color: Colors.pink,
                child: Text('audioFiles Fetch error ${snap.error}'));
          } else if (snap.connectionState != ConnectionState.waiting &&
              !snap.hasData) {
            return const ColoredBox(
                color: Colors.purple, child: Text('no audioFiles Fetch'));
          } else if (snap.data == null) {
            return const ColoredBox(
                color: Colors.blue, child: Text('audioFiles Fetch null'));
          } else {
            AudioState.allAudioFiles = snap.data!;
            return AnimatedList(
              initialItemCount: snap.data!.all.length,
              padding: const EdgeInsets.symmetric(vertical: 15),
              key: Globals.audioListKey,
              itemBuilder: (context, index, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: AudioBubble(
                    fileSyncStatus: snap.data!.all[index],
                    key: ValueKey(snap.data!.all[index]),
                  ),
                );
              },
            );
          }
        });
  }
}
