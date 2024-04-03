import 'dart:async';
import 'dart:io';
import 'package:vocal_message/src/file_status.dart';
import 'package:vocal_message/src/messages/audio_state.dart';
import 'package:vocal_message/src/azure_blob/azblob_abstract.dart';
import 'package:vocal_message/src/globals.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AudioRecPlayer extends StatefulWidget {
  /// Path from where to play recorded audio
  final String source;

  /// Callback when audio file should be removed
  /// Setting this to null hides the delete button
  final VoidCallback onDoneOrDelete;

  const AudioRecPlayer({
    Key? key,
    required this.source,
    required this.onDoneOrDelete,
  }) : super(key: key);

  @override
  AudioRecPlayerState createState() => AudioRecPlayerState();
}

class AudioRecPlayerState extends State<AudioRecPlayer> {
  static const double _controlSize = 56;
  static const double _deleteBtnSize = 24;

  final _audioPlayer = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
  late StreamSubscription<void> _playerStateChangedSubscription;
  late StreamSubscription<Duration?> _durationChangedSubscription;
  late StreamSubscription<Duration> _positionChangedSubscription;
  Duration? _position;
  Duration? _duration;

  @override
  void initState() {
    _playerStateChangedSubscription =
        _audioPlayer.onPlayerComplete.listen((state) async {
      await _audioPlayer.stop();
      setState(() {});
    });
    _positionChangedSubscription = _audioPlayer.onPositionChanged
        .listen((position) => setState(() => _position = position));
    _durationChangedSubscription = _audioPlayer.onDurationChanged
        .listen((duration) => setState(() => _duration = duration));

    super.initState();
  }

  @override
  void dispose() {
    _playerStateChangedSubscription.cancel();
    _positionChangedSubscription.cancel();
    _durationChangedSubscription.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                _buildControl(),
                _buildSlider(constraints.maxWidth - _controlSize),
                ClipOval(
                  child: Material(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    child: InkWell(
                      child: const SizedBox(
                        width: _controlSize,
                        height: _controlSize,
                        child: Icon(Icons.delete,
                            color: Color(0xFF73748D), size: _deleteBtnSize),
                      ),
                      onTap: () {
                        if (_audioPlayer.state == PlayerState.playing) {
                          _audioPlayer
                              .stop()
                              .then((value) => widget.onDoneOrDelete());
                        } else {
                          widget.onDoneOrDelete();
                        }
                        File(widget.source).delete();
                      },
                    ),
                  ),
                ),
              ],
            ),
            // wrap this in a green circle
            ClipOval(
              child: Material(
                color: Theme.of(context).colorScheme.secondary,
                child: InkWell(
                  child: IconButton(
                    icon: const Icon(Icons.upload, color: Colors.white),
                    onPressed: () async {
                      VocalMessagesConfig.client = http.Client();
                      AudioState.allAudioFiles.myFiles.add(
                          MyFileStatus(SyncStatus.localSyncing, widget.source));
                      if (VocalMessagesConfig.audioListKey.currentState !=
                          null) {
                        VocalMessagesConfig.audioListKey.currentState!
                            .insertItem(
                                AudioState.allAudioFiles.all.length - 1);
                      }
                      final dd = await AzureBlobAbstract.uploadAudioWavToAzure(
                          widget.source,
                          VocalMessagesConfig.config.myFilesPath +
                              '/' +
                              widget.source.nameOnly,
                          VocalMessagesConfig.client);
                      if (dd == true) {
                        VocalMessagesConfig.client.close();
                        final index = AudioState.allAudioFiles.myFiles
                            .indexWhere((e) =>
                                e.uploadStatus == SyncStatus.localSyncing &&
                                e.filePath == widget.source);
                        AudioState.allAudioFiles.myFiles[index] =
                            MyFileStatus(SyncStatus.synced, widget.source);
                        VocalMessagesConfig.audioListKey.currentState!
                            .setState(() {});
                      }
                      debugPrint(widget.source);
                      widget.onDoneOrDelete();
                    },
                  ),
                ),
              ),
            ),
            if (_duration != null)
              Text(
                  '${_position?.inSeconds ?? ''} / ${_duration?.inSeconds ?? ''} sec'),
          ],
        );
      },
    );
  }

  Widget _buildControl() {
    Icon icon;
    Color color;

    if (_audioPlayer.state == PlayerState.playing) {
      icon = const Icon(Icons.pause, color: Colors.red, size: 30);
      color = Colors.red.withOpacity(0.1);
    } else {
      final theme = Theme.of(context);
      icon = const Icon(Icons.play_arrow, color: Color(0xFF73748D), size: 30);
      color = theme.primaryColor.withOpacity(0.1);
    }

    return ClipOval(
      child: Material(
        color: color,
        child: InkWell(
          child:
              SizedBox(width: _controlSize, height: _controlSize, child: icon),
          onTap: () {
            if (_audioPlayer.state == PlayerState.playing) {
              _audioPlayer.pause();
            } else {
              play();
            }
          },
        ),
      ),
    );
  }

  Widget _buildSlider(double widgetWidth) {
    bool canSetValue = false;
    final duration = _duration;
    final position = _position;

    if (duration != null && position != null) {
      canSetValue = position.inMilliseconds > 0;
      canSetValue &= position.inMilliseconds < duration.inMilliseconds;
    }

    double width = widgetWidth - _controlSize - _deleteBtnSize;
    width -= _deleteBtnSize;

    return SizedBox(
      width: width,
      child: Slider(
        activeColor: Theme.of(context).primaryColor,
        inactiveColor: Theme.of(context).colorScheme.secondary,
        onChanged: (v) {
          if (duration != null) {
            final position = v * duration.inMilliseconds;
            _audioPlayer.seek(Duration(milliseconds: position.round()));
          }
        },
        value: canSetValue && duration != null && position != null
            ? position.inMilliseconds / duration.inMilliseconds
            : 0.0,
      ),
    );
  }

  Future<void> play() {
    return _audioPlayer.play(
      kIsWeb ? UrlSource(widget.source) : DeviceFileSource(widget.source),
    );
  }
}
