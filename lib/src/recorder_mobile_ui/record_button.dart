import 'dart:async';
import 'dart:io';
import 'package:vocal_message/src/azure_blob/azblob_abstract.dart';
import 'package:vocal_message/src/file_status.dart';
import 'package:path/path.dart' as p;
import 'package:vocal_message/src/messages/audio_state.dart';
import 'package:vocal_message/src/globals.dart';
import 'package:vocal_message/src/recorder_mobile_ui/flow_shader.dart';
import 'package:vocal_message/src/recorder_mobile_ui/lottie_animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:record/record.dart';
import 'package:http/http.dart' as http;

class RecorderMobileView extends StatefulWidget {
  // final AnimationController controller;
  const RecorderMobileView({
    // required this.controller,
    Key? key,
  }) : super(key: key);

  @override
  State<RecorderMobileView> createState() => _RecorderMobileViewState();
}

class _RecorderMobileViewState extends State<RecorderMobileView>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;

  static const double size = 50;

  final double lockerHeight = 200;
  double cancelTimerWidth = 0;
  double lockTimerWidth = 0;

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
  // ignore: unused_field
  Amplitude? _amplitude;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    buttonScaleAnimation = Tween<double>(begin: 1, end: 2).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticInOut),
      ),
    );
    controller.addListener(() => setState(() {}));

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
    lockTimerWidth = MediaQuery.of(context).size.width * 0.7;
    cancelTimerWidth = MediaQuery.of(context).size.width -
        (6.2 * VocalMessagesConfig.defaultPadding);
    timerAnimation = Tween<double>(
            begin: (cancelTimerWidth) + VocalMessagesConfig.defaultPadding,
            end: 0)
        .animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.2, 1, curve: Curves.easeIn),
      ),
    );
    lockerAnimation = Tween<double>(
            begin: lockerHeight + VocalMessagesConfig.defaultPadding, end: 0)
        .animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.2, 1, curve: Curves.easeIn),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
// FROM recorder
    _timer?.cancel();
    _recordSub?.cancel();
    _amplitudeSub?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  ///
  /// FROM RECORDER LIB
  Future<void> _start() async {
    try {
      // no longer necessary, already checked before
      // if (await _audioRecorder.hasPermission())
      {
        const encoder = AudioEncoder.wav;

        // We don't do anything with this but printing
        final isSupported = await _audioRecorder.isEncoderSupported(encoder);

        debugPrint('${encoder.name} supported: $isSupported');

        final devs = await _audioRecorder.listInputDevices();
        debugPrint(devs.toString());

        const config =
            RecordConfig(encoder: encoder, numChannels: 1, sampleRate: 16000);

        // Record to file
        String path;
        if (kIsWeb) {
          path = '';
        } else {
          path = p.join(VocalMessagesConfig.myFilesDir.path,
              'audio_${DateTime.now().millisecondsSinceEpoch}.wav');
        }
        await _audioRecorder.start(config, path: path);
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
    debugPrint('stopPath $stopPath');
    return stopPath;
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

  Widget _buildTimerText() {
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
        if (isLocked)
          timerLocked()
        else ...[
          if (_recordState == RecordState.record) ...[
            cancelSlider(),
            lockSlider(),
          ],
          audioButton(),
        ]
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
          borderRadius: BorderRadius.circular(VocalMessagesConfig.borderRadius),
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
              child: const Column(
                children: [
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
        width: cancelTimerWidth,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(VocalMessagesConfig.borderRadius),
          color: Colors.red,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: [
              showLottie ? const LottieAnimation() : _buildTimerText(),
              const SizedBox(width: size),
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
    return SizedBox(
      height: size * 2, // _recordState == RecordState.pause ? size * 2 :
      width: lockTimerWidth,
      child: Padding(
        padding: const EdgeInsets.only(left: 5, right: 5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTimerText(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.max,
              children: [
                _buildDeleteButton(),
                _buildPauseResumeControl(),
                _buildUploadButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadButton() => IconButton(
        icon: const Icon(Icons.upload, color: Colors.lightBlueAccent),
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
          VocalMessagesConfig.client = http.Client();
          AudioState.allAudioFiles.myFiles
              .add(MyFileStatus(SyncStatus.localSyncing, filePath));
          VocalMessagesConfig.audioListKey.currentState!
              .insertItem(AudioState.allAudioFiles.all.length - 1);
          final dd = await AzureBlobAbstract.uploadAudioWavToAzure(
              filePath,
              VocalMessagesConfig.config.myFilesPath + '/' + filePath.nameOnly,
              VocalMessagesConfig.client);
          if (dd == true) {
            VocalMessagesConfig.client.close();
            final index = AudioState.allAudioFiles.myFiles.indexWhere((e) =>
                e.uploadStatus == SyncStatus.localSyncing &&
                e.filePath == filePath);
            AudioState.allAudioFiles.myFiles[index] =
                MyFileStatus(SyncStatus.synced, filePath);
            VocalMessagesConfig.audioListKey.currentState!.setState(() {});
          }
          debugPrint(filePath);
        },
      );

  Widget _buildDeleteButton() => GestureDetector(
        child: const Icon(
          Icons.delete,
          size: 22,
          color: Colors.grey,
        ),
        onLongPress: () async {
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
      );

  Widget _buildPauseResumeControl() {
    if (_recordState == RecordState.stop) {
      return const SizedBox.shrink();
    }

    late Icon icon;
    late Color color;

    // ** more like whatsapp
    final theme = Theme.of(context);
    if (_recordState == RecordState.record) {
      icon = const Icon(Icons.pause, color: Colors.red, size: 22);
      color = theme.primaryColor.withOpacity(0.8);
    } else {
      icon = const Icon(Icons.pause, color: Colors.red, size: 22);
      color = theme.primaryColor.withOpacity(0.2);
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
        controller.forward();
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
            controller.reverse();
            debugPrint("Cancelled recording");
            var filePath = await _stop();
            debugPrint(filePath);
            File(filePath!).delete();
            debugPrint("Deleted $filePath");
            showLottie = false;
          });
        } else if (checkIsLocked(details.localPosition)) {
          controller.reverse();
          if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
            Vibrate.feedback(FeedbackType.heavy);
          }
          debugPrint("Locked recording");
          debugPrint(details.localPosition.dy.toString());
          setState(() => isLocked = true);
        } else {
          controller.reverse();
          if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
            Vibrate.feedback(FeedbackType.success);
          }
          final filePath = await _stop();
          if (filePath == null) {
            return;
          }
          VocalMessagesConfig.client = http.Client();
          AudioState.allAudioFiles.myFiles
              .add(MyFileStatus(SyncStatus.localSyncing, filePath));
          VocalMessagesConfig.audioListKey.currentState!
              .insertItem(AudioState.allAudioFiles.all.length - 1);
          final dd = await AzureBlobAbstract.uploadAudioWavToAzure(
              filePath,
              VocalMessagesConfig.config.myFilesPath + '/' + filePath.nameOnly,
              VocalMessagesConfig.client);
          if (dd == true) {
            VocalMessagesConfig.client.close();
            final index = AudioState.allAudioFiles.myFiles.indexWhere((e) =>
                e.uploadStatus == SyncStatus.localSyncing &&
                e.filePath == filePath);
            AudioState.allAudioFiles.myFiles[index] =
                MyFileStatus(SyncStatus.synced, filePath);
            VocalMessagesConfig.audioListKey.currentState!.setState(() {});
          }
          debugPrint(filePath);
        }
      },
      onLongPressCancel: () {
        debugPrint("onLongPressCancel");
        controller.reverse();
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
