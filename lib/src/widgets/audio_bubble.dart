import 'package:vocal_message/example/const.dart';
import 'package:vocal_message/src/azure_blob/azblob_abstract.dart';
import 'package:vocal_message/src/file_status.dart';
import 'package:vocal_message/src/globals.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class AudioBubble<F extends FileSyncStatus> extends StatelessWidget {
  final F fileSyncStatus;
  const AudioBubble({Key? key, required this.fileSyncStatus}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (fileSyncStatus is MyFileStatus)
            SizedBox(width: MediaQuery.of(context).size.width * 0.4),
          Expanded(
            child: Container(
              height: 45,
              padding: const EdgeInsets.only(left: 12, right: 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Globals.borderRadius - 10),
                color: fileSyncStatus is MyFileStatus
                    ? Colors.black
                    : Colors.blueGrey[900],
              ),
              child: AudioBubbleWidget(
                  fileSyncStatus, fileSyncStatus is MyFileStatus),
            ),
          ),
          if (fileSyncStatus is TheirFileStatus)
            SizedBox(width: MediaQuery.of(context).size.width * 0.4),
        ],
      ),
    );
  }
}

class AudioBubbleWidget<F extends FileSyncStatus> extends StatefulWidget {
  F fileSyncStatus;
  final bool isMyVoice;
  AudioBubbleWidget(this.fileSyncStatus, this.isMyVoice, {Key? key})
      : super(key: key);

  @override
  State<AudioBubbleWidget> createState() => _AudioBubbleWidgetState();
}

class _AudioBubbleWidgetState extends State<AudioBubbleWidget> {
  final player = AudioPlayer();
  Duration? duration;

  @override
  void initState() {
    super.initState();
    player.setFilePath(widget.fileSyncStatus.filePath).then((value) {
      setState(() {
        duration = value;
      });
    });
  }

  String prettyDuration(Duration d) {
    var min = d.inMinutes < 10 ? "0${d.inMinutes}" : d.inMinutes.toString();
    var sec = d.inSeconds < 10 ? "0${d.inSeconds}" : d.inSeconds.toString();
    return min + ":" + sec;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 4),
        Row(
          children: [
            if (widget.fileSyncStatus.status == SyncStatus.remoteNotSynced)
              IconButton(
                  onPressed: () async {
                    setState(() {
                      if (widget.fileSyncStatus is MyFileStatus) {
                        widget.fileSyncStatus = MyFileStatus(
                            SyncStatus.syncing, widget.fileSyncStatus.filePath);
                      } else {
                        widget.fileSyncStatus = TheirFileStatus(
                            SyncStatus.syncing, widget.fileSyncStatus.filePath);
                      }
                    });
                    //TODO check connectivity
                    final audio =
                        await AzureBlobAbstract.downloadAudioFromAzure(
                            downloadPath +
                                '/' +
                                widget.fileSyncStatus.filePath);
                    //TODO save file
                  },
                  icon: const Icon(Icons.download))
            else if (widget.fileSyncStatus.status == SyncStatus.syncing)
              const CircularProgressIndicator()
            else
              StreamBuilder<PlayerState>(
                stream: player.playerStateStream,
                builder: (context, snapshot) {
                  final playerState = snapshot.data;
                  final processingState = playerState?.processingState;
                  final playing = playerState?.playing;
                  if (processingState == ProcessingState.loading ||
                      processingState == ProcessingState.buffering) {
                    return GestureDetector(
                      child: const Icon(Icons.play_arrow),
                      onTap: player.play,
                    );
                  } else if (playing != true) {
                    return GestureDetector(
                      child: const Icon(Icons.play_arrow),
                      onTap: player.play,
                    );
                  } else if (processingState != ProcessingState.completed) {
                    return GestureDetector(
                      child: const Icon(Icons.pause),
                      onTap: player.pause,
                    );
                  } else {
                    return GestureDetector(
                      child: const Icon(Icons.replay),
                      onTap: () {
                        player.seek(Duration.zero);
                      },
                    );
                  }
                },
              ),
            const SizedBox(width: 8),
            if (widget.fileSyncStatus.status == SyncStatus.syncing ||
                widget.fileSyncStatus.status == SyncStatus.remoteNotSynced)
              const SizedBox()
            else
              Expanded(
                child: StreamBuilder<Duration>(
                  stream: player.positionStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Column(
                        children: [
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: snapshot.data!.inMilliseconds /
                                (duration?.inMilliseconds ?? 1),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (duration == null)
                                const SizedBox()
                              else
                                Text(
                                  prettyDuration(snapshot.data! == Duration.zero
                                      ? duration ?? Duration.zero
                                      : snapshot.data!),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                              //TODO remove this before publishing
                              Text(
                                widget.fileSyncStatus.status.toString(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    } else {
                      return const LinearProgressIndicator();
                    }
                  },
                ),
              ),
          ],
        ),
        // not working yet
        // AmplitudeWidget(true, player, widget.filepath),
      ],
    );
  }
}
