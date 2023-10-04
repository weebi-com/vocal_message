import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:intl/intl.dart' as intl;
import 'package:vocal_message/src/azure_blob/azblob_abstract.dart';
import 'package:vocal_message/src/file_status.dart';
import 'package:vocal_message/src/globals.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;

final dateTimeFormatter =
    intl.DateFormat('dd/MM/yyyy HH:mm:ss', Globals.locale);

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

  Future<Uint8List> _downloadFromAzure() async {
    // here close Globals.client if needed
    Globals.client = http.Client();
    final path =
        Globals.azureTheirFilesPath + '/' + widget.fileSyncStatus.filePath;
    print('path $path');
    final audio =
        await AzureBlobAbstract.downloadAudioFromAzure(path, Globals.client);
    return audio;
  }

  Future<void> downloadAndSaveFile() async {
    setState(() {
      widget.fileSyncStatus = (widget.fileSyncStatus as TheirFileStatus)
          .copyWith(downloadStatus: SyncStatus.remoteSyncing);
    });
    final uint8List = await _downloadFromAzure();
    if (uint8List.isEmpty) {
      debugPrint('user interrupted download');
      return;
    }
    print('uint8List.lengthInBytes ${uint8List.lengthInBytes}');
    setState(() {
      widget.fileSyncStatus = (widget.fileSyncStatus as TheirFileStatus)
          .copyWith(downloadStatus: SyncStatus.synced);
    });
    //
    Globals.client.close();
    //
    final temp = (widget.fileSyncStatus as TheirFileStatus).localPathFull;
    if (temp.isEmpty) {
      debugPrint('widget.fileSyncStatus.localPathFull is empty');
      return;
    }
    try {
      // await save(temp, uint8List);
      await File(temp).writeAsBytes(uint8List);
      // save(temp, uint8List);
      debugPrint('save file success in $temp');

      player
          .setFilePath((widget.fileSyncStatus as TheirFileStatus).localPathFull)
          .then((value) {
        setState(() {
          duration = value;
        });
      });
    } on FileSystemException catch (e) {
      debugPrint('save file exception $e');
      setState(() {
        widget.fileSyncStatus = (widget.fileSyncStatus as TheirFileStatus)
            .copyWith(downloadStatus: SyncStatus.remoteNotSynced);
      });
    }
  }

  Future<void> upload() async {
    Globals.client = http.Client();
    setState(() {
      widget.fileSyncStatus = (widget.fileSyncStatus as MyFileStatus)
          .copyWith(uploadStatus: SyncStatus.localSyncing);
    });
    final isUploadOk = await AzureBlobAbstract.uploadAudioWavToAzure(
        widget.fileSyncStatus.filePath,
        Globals.azureMyFilesPath +
            '/' +
            widget.fileSyncStatus.filePath.nameOnly,
        Globals.client);
    if (isUploadOk) {
      setState(() {
        widget.fileSyncStatus = (widget.fileSyncStatus as MyFileStatus)
            .copyWith(uploadStatus: SyncStatus.synced);
      });
      Globals.client.close();
    }
    return;
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
                icon: const Icon(Icons.download),
                onPressed: () async => downloadAndSaveFile(),
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
                  Globals.client.close();
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: const [
                    Icon(Icons.cancel),
                    CircularProgressIndicator(),
                  ],
                ),
              )
            else
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
                      dateTimeFormatter
                          .format(widget.fileSyncStatus.dateLastModif),
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
                                dateTimeFormatter.format(
                                    widget.fileSyncStatus.dateLastModif),
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
                  Globals.client.close();
                  return;
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: const [
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
