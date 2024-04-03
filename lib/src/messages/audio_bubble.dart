import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:vocal_message/logic.dart';
import 'package:vocal_message/src/azure_blob/azblob_abstract.dart';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;

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
            SizedBox(width: MediaQuery.of(context).size.width * 0.2),
          Expanded(
            child: Container(
              height: 52,
              padding: const EdgeInsets.only(left: 10, right: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                    VocalMessagesConfig.borderRadius - 10),
                color: fileSyncStatus is MyFileStatus
                    ? Colors.black
                    : Colors.blueGrey[900],
              ),
              child: AudioBubbleWidget(
                  fileSyncStatus, fileSyncStatus is MyFileStatus),
            ),
          ),
          if (fileSyncStatus is TheirFileStatus)
            SizedBox(width: MediaQuery.of(context).size.width * 0.2),
        ],
      ),
    );
  }
}

// ignore: must_be_immutable
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
    if (widget.fileSyncStatus is MyFileStatus) {
      player.setFilePath(widget.fileSyncStatus.filePath).then((value) {
        if (mounted) {
          setState(() => duration = value);
        }
      });
    } else {
      //widget.fileSyncStatus is TheirFileStatus
      if ((widget.fileSyncStatus as TheirFileStatus).localPathFull.isNotEmpty) {
        final localPathFull =
            (widget.fileSyncStatus as TheirFileStatus).localPathFull;

        player.setFilePath(localPathFull).then((value) {
          if (mounted) {
            setState(() => duration = value);
          }
        });
      }
    }
  }

  String prettyDuration(Duration d) {
    var min = d.inMinutes < 10 ? "0${d.inMinutes}" : d.inMinutes.toString();
    var sec = d.inSeconds < 10 ? "0${d.inSeconds}" : d.inSeconds.toString();
    return min + ":" + sec;
  }

  String prettyAzureLength(int contentLength) {
    debugPrint('contentLength $contentLength');
    final megaBytes = (contentLength * 0.000001);
    num fac = pow(10, 2);
    final d = (megaBytes * fac).round() / fac;

    return '$d Mo';
  }

  Future<Uint8List> _downloadTheirAudio() async {
    setState(() {
      widget.fileSyncStatus = (widget.fileSyncStatus as TheirFileStatus)
          .copyWith(downloadStatus: SyncStatus.remoteSyncing);
    });
    VocalMessagesConfig.client = http.Client();

    final uint8List = await AzureBlobAbstract.downloadAudioFromAzure(
        VocalMessagesConfig.config
                .theirFilesPath + // only makes sense to download audio from someone else
            '/' +
            widget.fileSyncStatus.filePath,
        VocalMessagesConfig.client);

    if (uint8List.isEmpty) {
      debugPrint('user interrupted download');
      return Uint8List.fromList([]);
    }
    return uint8List;
  }

  Future<void> upload() async {
    VocalMessagesConfig.client = http.Client();
    setState(() {
      widget.fileSyncStatus = (widget.fileSyncStatus as MyFileStatus)
          .copyWith(uploadStatus: SyncStatus.localSyncing);
    });
    final isUploadOk = await AzureBlobAbstract.uploadAudioWavToAzure(
        widget.fileSyncStatus.filePath,
        VocalMessagesConfig.config.myFilesPath +
            '/' +
            widget.fileSyncStatus.filePath.nameOnly,
        VocalMessagesConfig.client);
    if (isUploadOk) {
      setState(() {
        widget.fileSyncStatus = (widget.fileSyncStatus as MyFileStatus)
            .copyWith(uploadStatus: SyncStatus.synced);
      });
      VocalMessagesConfig.client.close();
    }
    return;
  }

  @override
  Widget build(BuildContext context) {
    final dateString =
        '${widget.fileSyncStatus.dateLastModif.year}/${widget.fileSyncStatus.dateLastModif.month}/${widget.fileSyncStatus.dateLastModif.day} ${widget.fileSyncStatus.dateLastModif.hour}:${widget.fileSyncStatus.dateLastModif.minute}';
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 4),
        Row(
          children: [
            if (widget.fileSyncStatus.status == SyncStatus.localDefective)
              const Icon(Icons.broken_image, color: Colors.red),
            if (widget.fileSyncStatus.status == SyncStatus.remoteNotSynced)
              IconButton(
                icon: const Icon(Icons.download),
                onPressed: () async {
                  final audioContent = await _downloadTheirAudio();
                  if (audioContent.isEmpty ||
                      audioContent.lengthInBytes < 250) {
                    return;
                  }
                  final temp = (widget.fileSyncStatus as TheirFileStatus)
                      .filePath
                      .nameOnly
                      .localPathFull;

                  debugPrint('temp path :  $temp');
                  if (temp.isEmpty) {
                    return;
                  }
                  try {
                    final temp2 = await File(temp).writeAsBytes(audioContent);
                    // final contentLength = await temp2.length();
                    VocalMessagesConfig.client.close();
                    if (temp2.path.isNotEmpty) {
                      debugPrint('save file success in $temp');
                      try {
                        final path = await player.setFilePath(temp2.path);
                        setState(() {
                          duration = path;
                          widget.fileSyncStatus =
                              (widget.fileSyncStatus as TheirFileStatus)
                                  .copyWith(downloadStatus: SyncStatus.synced);
                        });
                      } on PlayerException catch (e) {
                        debugPrint('Source error $e');
                        setState(() {
                          widget.fileSyncStatus = (widget.fileSyncStatus
                                  as TheirFileStatus)
                              .copyWith(
                                  downloadStatus: SyncStatus.localDefective);
                        });
                      }
                    }
                  } on FileSystemException catch (e) {
                    debugPrint('save file exception $e');
                    setState(() {
                      widget.fileSyncStatus = (widget.fileSyncStatus
                              as TheirFileStatus)
                          .copyWith(downloadStatus: SyncStatus.remoteNotSynced);
                    });
                  }
                },
              )
            else if (widget.fileSyncStatus.status == SyncStatus.remoteSyncing)
              GestureDetector(
                onTap: () {
                  setState(() {
                    widget.fileSyncStatus =
                        (widget.fileSyncStatus as TheirFileStatus).copyWith(
                      downloadStatus: SyncStatus.remoteNotSynced,
                    );
                  });
                  VocalMessagesConfig.client.close();
                },
                child: const Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.cancel),
                    CircularProgressIndicator(),
                  ],
                ),
              )
            else if (widget.fileSyncStatus.status != SyncStatus.localDefective)
              StreamBuilder<PlayerState>(
                stream: player.playerStateStream,
                builder: (context, snapshot) {
                  final playerState = snapshot.data;
                  final processingState = playerState?.processingState;
                  final playing = playerState?.playing;
                  if (processingState == ProcessingState.loading ||
                      processingState == ProcessingState.buffering) {
                    return IconButton(
                      icon: const Icon(Icons.play_arrow),
                      onPressed: player.play,
                    );
                  } else if (playing != true) {
                    return IconButton(
                      icon: const Icon(Icons.play_arrow),
                      onPressed: player.play,
                    );
                  } else if (processingState != ProcessingState.completed) {
                    return IconButton(
                      icon: const Icon(Icons.pause),
                      onPressed: player.pause,
                    );
                  } else {
                    return IconButton(
                      icon: const Icon(Icons.replay),
                      onPressed: () {
                        player.seek(Duration.zero);
                      },
                    );
                  }
                },
              ),
            const SizedBox(width: 6),
            if (widget.fileSyncStatus.status == SyncStatus.remoteSyncing ||
                widget.fileSyncStatus.status == SyncStatus.remoteNotSynced)
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      prettyAzureLength(
                          (widget.fileSyncStatus as TheirFileStatus).bytes),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      dateString,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              )
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
                              if (duration != null)
                                Text(
                                  prettyDuration(snapshot.data! == Duration.zero
                                      ? duration ?? Duration.zero
                                      : snapshot.data!),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                              Text(
                                dateString,
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
            if (widget.fileSyncStatus.status == SyncStatus.localNotSynced)
              IconButton(
                icon: const Icon(Icons.upload, color: Colors.lightBlueAccent),
                onPressed: () async => upload(),
              ),
            if (widget.fileSyncStatus.status == SyncStatus.localSyncing)
              GestureDetector(
                onTap: () {
                  setState(() {
                    widget.fileSyncStatus =
                        (widget.fileSyncStatus as MyFileStatus)
                            .copyWith(uploadStatus: SyncStatus.localNotSynced);
                  });
                  VocalMessagesConfig.client.close();
                  return;
                },
                child: const Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.cancel),
                    CircularProgressIndicator(),
                  ],
                ),
              )
          ],
        ),
        // not working yet
        // AmplitudeWidget(true, player, widget.filepath),
      ],
    );
  }
}
