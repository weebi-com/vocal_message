import 'dart:async';
import 'dart:io';
import 'package:vocal_message/src/azure_blob/azblob_abstract.dart';
import 'package:vocal_message/src/file_status.dart';
import 'package:path/path.dart' as p;
import 'package:vocal_message/src/audio_state.dart';
import 'package:vocal_message/src/globals.dart';
import 'package:vocal_message/src/widgets/flow_shader.dart';
import 'package:vocal_message/src/widgets/lottie_animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:record/record.dart';
import 'package:http/http.dart' as http;

//TODO : make upload cancelable
class RecorderMobileView extends StatefulWidget {
  final AnimationController controller;
  const RecorderMobileView({
    required this.controller,
    Key? key,
  }) : super(key: key);

  @override
  State<RecorderMobileView> createState() => _RecorderMobileViewState();
}

class _RecorderMobileViewState extends State<RecorderMobileView> {
  static const double size = 55;

  final double lockerHeight = 200;
  double timerWidth = 0;

  late Animation<double> buttonScaleAnimation;
  late Animation<double> timerAnimation;
  late Animation<double> lockerAnimation;

  bool isLocked = false;
  bool showLottie = false;

  /// coming from recorder
  int _recordDuration = 0;
  Timer? _timer;
  late final AudioRecorder _audioRecorder;
  StreamSubscription<RecordState>? _recordSub;
  RecordState _recordState = RecordState.stop;
  StreamSubscription<Amplitude>? _amplitudeSub;
  Amplitude? _amplitude;

  @override
  void initState() {
    super.initState();
    buttonScaleAnimation = Tween<double>(begin: 1, end: 2).animate(
      CurvedAnimation(
        parent: widget.controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticInOut),
      ),
    );
    widget.controller.addListener(() {
      setState(() {});
    });

    // coming from recorder
    _audioRecorder = AudioRecorder();

    _recordSub = _audioRecorder.onStateChanged().listen((recordState) {
      _updateRecordState(recordState);
    });

    _amplitudeSub = _audioRecorder
        .onAmplitudeChanged(const Duration(milliseconds: 300))
        .listen((amp) {
      setState(() => _amplitude = amp);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    timerWidth =
        MediaQuery.of(context).size.width - 20 * Globals.defaultPadding - 4;
    timerAnimation =
        Tween<double>(begin: timerWidth + Globals.defaultPadding, end: 0)
            .animate(
      CurvedAnimation(
        parent: widget.controller,
        curve: const Interval(0.2, 1, curve: Curves.easeIn),
      ),
    );
    lockerAnimation =
        Tween<double>(begin: lockerHeight + Globals.defaultPadding, end: 0)
            .animate(
      CurvedAnimation(
        parent: widget.controller,
        curve: const Interval(0.2, 1, curve: Curves.easeIn),
      ),
    );
  }

  @override
  void dispose() {
// FROM recorder
    _timer?.cancel();
    _recordSub?.cancel();
    _amplitudeSub?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  /// FROM RECORDER LIB
  ///
  Future<void> _start() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        const encoder = AudioEncoder.wav;

        // We don't do anything with this but printing
        final isSupported = await _audioRecorder.isEncoderSupported(encoder);

        debugPrint('${encoder.name} supported: $isSupported');

        final devs = await _audioRecorder.listInputDevices();
        debugPrint(devs.toString());

        const config = RecordConfig(encoder: encoder, numChannels: 1);

        // Record to file
        String path;
        if (kIsWeb) {
          path = '';
        } else {
          path = p.join(Globals.myFilesDir.path,
              'audio_${DateTime.now().millisecondsSinceEpoch}.wav');
        }
        await _audioRecorder.start(config, path: path);

        // Record to stream
        // final file = File(path);
        // final stream = await _audioRecorder.startStream(config);
        // stream.listen(
        //   (data) {
        //     // ignore: avoid_print
        //     print(
        //       _audioRecorder.convertBytesToInt16(Uint8List.fromList(data)),
        //     );
        //     file.writeAsBytesSync(data, mode: FileMode.append);
        //   },
        //   // ignore: avoid_print
        //   onDone: () => print('End of stream'),
        // );

        _recordDuration = 0;

        _startTimer();
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  Future<String?> _stop() async {
    final stopPath = await _audioRecorder.stop();
    //debugPrint('stopPath $stopPath');
    return stopPath;

    // TODO check if really needed, this comes from recorder lib
    // if (path != null) {
    //   // widget.onStop(path);
    // }

    // Simple download code for web testing
    // final anchor = html.document.createElement('a') as html.AnchorElement
    //   ..href = path
    //   ..style.display = 'none'
    //   ..download = 'audio.wav';
    // html.document.body!.children.add(anchor);

    // // download
    // anchor.click();

    // // cleanup
    // html.document.body!.children.remove(anchor);
    // html.Url.revokeObjectUrl(path!);
  }

  //Future<void> _pause() => _audioRecorder.pause();
  //Future<void> _resume() => _audioRecorder.resume();
  void _updateRecordState(RecordState recordState) {
    setState(() => _recordState = recordState);

    switch (recordState) {
      case RecordState.pause:
        _timer?.cancel();
        break;
      case RecordState.record:
        _startTimer();
        break;
      case RecordState.stop:
        _timer?.cancel();
        _recordDuration = 0;
        break;
    }
  }

  Widget _buildText() {
    if (_recordState != RecordState.stop) {
      return _buildTimer();
    }

    return const Text('');
  }

  Widget _buildTimer() {
    final String minutes = _formatNumber(_recordDuration ~/ 60);
    final String seconds = _formatNumber(_recordDuration % 60);

    return Text(
      '$minutes : $seconds',
      style: const TextStyle(color: Colors.white),
    );
  }

  String _formatNumber(int number) {
    String numberStr = number.toString();
    if (number < 10) {
      numberStr = '0$numberStr';
    }

    return numberStr;
  }

  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      setState(() => _recordDuration++);
    });
  }

  @override
  Widget build(BuildContext context) {
    // print('_recordState $_recordState');
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (isLocked == false && _recordState == RecordState.record) ...[
          lockSlider(),
          cancelSlider(),
        ],
        if (isLocked) timerLocked() else audioButton(),
      ],
    );
  }

  Widget lockSlider() {
    return Positioned(
      bottom: -lockerAnimation.value,
      child: Container(
        height: lockerHeight,
        width: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Globals.borderRadius),
          color: Colors.green,
        ),
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const FaIcon(FontAwesomeIcons.lock, size: 20),
            const SizedBox(height: 8),
            FlowShader(
              direction: Axis.vertical,
              child: Column(
                children: const [
                  Icon(Icons.keyboard_arrow_up),
                  Icon(Icons.keyboard_arrow_up),
                  Icon(Icons.keyboard_arrow_up),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget cancelSlider() {
    return Positioned(
      right: -timerAnimation.value,
      child: Container(
        height: size,
        width: timerWidth - 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Globals.borderRadius),
          color: Colors.red,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: [
              showLottie ? const LottieAnimation() : _buildText(),
              const SizedBox(width: 22),
              FlowShader(
                child: const Icon(Icons.keyboard_arrow_left),
                duration: const Duration(seconds: 3),
                flowColors: const [Colors.white, Colors.grey],
              ),
              const SizedBox(width: size),
            ],
          ),
        ),
      ),
    );
  }

  Widget timerLocked() {
    return
        //Positioned(
        //  right: 15,
        //  bottom: 15,
        //  child:
        Container(
      height: size,
      width: MediaQuery.of(context).size.width - 20,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Globals.borderRadius),
        color: Colors.grey,
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 15, right: 25),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.max,
          children: [
            if (_recordState == RecordState.pause)
              IconButton(
                icon: const Icon(
                  Icons.delete,
                  size: 18,
                  color: Colors.red,
                ),
                onPressed: () async {
                  setState(() {
                    _recordState == RecordState.stop;
                    isLocked = false;
                    showLottie = true;
                  });
                  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
                    Vibrate.feedback(FeedbackType.heavy);
                  }
                  var filePath = await _stop();
                  debugPrint(filePath);
                  File(filePath!).delete();
                  debugPrint("Deleted $filePath");
                },
              ),
            _buildText(),
            // Text(recordDuration),
            // FlowShader(
            //   child: const Text("Tap lock to stop"),
            //   duration: const Duration(seconds: 3),
            //   flowColors: const [Colors.white, Colors.grey],
            // ),
            const SizedBox(width: 10),
            _buildPauseResumeControl(),
            const SizedBox(width: 10),

            IconButton(
              icon: const FaIcon(
                FontAwesomeIcons.lock,
                size: 18,
                color: Colors.green,
              ),
              onPressed: () async {
                setState(() {
                  _recordState == RecordState.stop;
                  isLocked = false;
                });
                if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
                  Vibrate.feedback(FeedbackType.success);
                }
                final filePath = await _stop();
                if (filePath == null) {
                  return;
                }
                Globals.client = http.Client();
                AudioState.allAudioFiles.myFiles
                    .add(MyFileStatus(SyncStatus.localSyncing, filePath));
                Globals.audioListKey.currentState!
                    .insertItem(AudioState.allAudioFiles.all.length - 1);
                final dd = await AzureBlobAbstract.uploadAudioWavToAzure(
                    filePath,
                    Globals.azureMyFilesPath + '/' + filePath.nameOnly,
                    Globals.client);
                if (dd == true) {
                  Globals.client.close();
                  final index = AudioState.allAudioFiles.myFiles.indexWhere(
                      (e) =>
                          e.uploadStatus == SyncStatus.localSyncing &&
                          e.filePath == filePath);
                  AudioState.allAudioFiles.myFiles[index] =
                      MyFileStatus(SyncStatus.synced, filePath);
                  Globals.audioListKey.currentState!.setState(() {});
                }
                debugPrint(filePath);
              },
            ),
          ],
        ),
      ),
      //),
    );
  }

  Widget _buildPauseResumeControl() {
    if (_recordState == RecordState.stop) {
      return const SizedBox.shrink();
    }

    late Icon icon;
    late Color color;

    if (_recordState == RecordState.record) {
      icon = const Icon(Icons.pause, color: Colors.white, size: 18);
      color = Colors.blue.withOpacity(0.6);
    } else {
      final theme = Theme.of(context);
      icon = const Icon(Icons.mic, color: Colors.white, size: 18);
      color = theme.primaryColor.withOpacity(0.5);
    }

    return ClipOval(
      child: Material(
        color: color,
        child: InkWell(
          child: SizedBox(width: 44, height: 44, child: icon),
          onTap: () {
            if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
              Vibrate.feedback(FeedbackType.light);
            }
            (_recordState == RecordState.pause)
                ? _audioRecorder.resume()
                : _audioRecorder.pause();
          },
        ),
      ),
    );
  }

  Widget audioButton() {
    return GestureDetector(
      child: Transform.scale(
        scale: buttonScaleAnimation.value,
        child: Container(
          child: const Icon(Icons.mic),
          height: size,
          width: size,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ),
      onLongPressDown: (_) {
        debugPrint("onLongPressDown");
        widget.controller.forward();
      },
      onLongPressEnd: (details) async {
        debugPrint("onLongPressEnd");

        if (isCancelled(details.localPosition, context)) {
          if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
            Vibrate.feedback(FeedbackType.heavy);
          }

          setState(() {
            showLottie = true;
          });

          Timer(const Duration(milliseconds: 1440), () async {
            widget.controller.reverse();
            debugPrint("Cancelled recording");
            var filePath = await _stop();
            debugPrint(filePath);
            File(filePath!).delete();
            debugPrint("Deleted $filePath");
            showLottie = false;
          });
        } else if (checkIsLocked(details.localPosition)) {
          widget.controller.reverse();
          if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
            Vibrate.feedback(FeedbackType.heavy);
          }
          debugPrint("Locked recording");
          debugPrint(details.localPosition.dy.toString());
          setState(() {
            isLocked = true;
          });
        } else {
          widget.controller.reverse();
          if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
            Vibrate.feedback(FeedbackType.success);
          }
          final filePath = await _stop();
          if (filePath == null) {
            return;
          }
          Globals.client = http.Client();
          AudioState.allAudioFiles.myFiles
              .add(MyFileStatus(SyncStatus.localSyncing, filePath));
          Globals.audioListKey.currentState!
              .insertItem(AudioState.allAudioFiles.all.length - 1);
          final dd = await AzureBlobAbstract.uploadAudioWavToAzure(
              filePath,
              Globals.azureMyFilesPath + '/' + filePath.nameOnly,
              Globals.client);
          if (dd == true) {
            Globals.client.close();
            final index = AudioState.allAudioFiles.myFiles.indexWhere((e) =>
                e.uploadStatus == SyncStatus.localSyncing &&
                e.filePath == filePath);
            AudioState.allAudioFiles.myFiles[index] =
                MyFileStatus(SyncStatus.synced, filePath);
            Globals.audioListKey.currentState!.setState(() {});
          }
          debugPrint(filePath);
        }
      },
      onLongPressCancel: () {
        debugPrint("onLongPressCancel");
        widget.controller.reverse();
      },
      onLongPress: () async {
        debugPrint("onLongPress");
        if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
          Vibrate.feedback(FeedbackType.success);
        }
        if (await _audioRecorder.hasPermission()) {
          await _start();
        }
      },
    );
  }

  bool checkIsLocked(Offset offset) {
    return (offset.dy < -35);
  }

  bool isCancelled(Offset offset, BuildContext context) {
    return (offset.dx < -(MediaQuery.of(context).size.width * 0.2));
  }
}
