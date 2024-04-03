import 'package:vocal_message/src/messages/audio_state.dart';
import 'package:vocal_message/src/globals.dart';
import 'package:vocal_message/src/messages/audio_bubble.dart';
import 'package:flutter/material.dart';

typedef FutureGenerator = Future<AllAudioFiles> Function();

class AudioList extends StatelessWidget {
  final bool isConnected;
  final FutureGenerator generator;
  // final Function onRerun;
  const AudioList(this.isConnected, this.generator, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AllAudioFiles>(
        future: generator(),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return SizedBox(
                width: MediaQuery.of(context).size.width * 0.5,
                child: const CircularProgressIndicator());
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
            return const AudioBubblesListWidget();
          }
        });
  }
}

class AudioBubblesListWidget extends StatelessWidget {
  // final Function onRerun;
  const AudioBubblesListWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedList(
      initialItemCount: AudioState.allAudioFiles.all.length,
      padding: const EdgeInsets.symmetric(vertical: 15),
      key: VocalMessagesConfig.audioListKey,
      itemBuilder: (context, index, animation) {
        return FadeTransition(
          opacity: animation,
          child: AudioBubble(
            fileSyncStatus: AudioState.allAudioFiles.all[index],
            key: ValueKey(AudioState.allAudioFiles.all[index]),
          ),
        );
      },
    );
  }
}
