import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

// bad result on wider screen e.g. desktop
/// not working yet
class AmplitudeWidget extends StatefulWidget {
  final bool me;
  final AudioPlayer player;
  final String filepath;
  const AmplitudeWidget(this.me, this.player, this.filepath, {Key? key})
      : super(key: key);

  @override
  State<AmplitudeWidget> createState() => _AmplitudeWidgetState();
}

class _AmplitudeWidgetState extends State<AmplitudeWidget>
    with TickerProviderStateMixin {
  AnimationController? _controller;
  Duration? _audioDuration;
  int duration = 0;
  double maxDurationForSlider = .0000001;

  @override
  void initState() {
    _setDuration();
    super.initState();
  }

  void _setDuration() async {
    if (widget.player.duration != null) {
      _audioDuration = widget.player.duration;
    } else {
      _audioDuration = await AudioPlayer().setFilePath(widget.filepath);
    }
    duration = _audioDuration!.inMilliseconds;
    maxDurationForSlider = duration + .0;

    ///
    _controller = AnimationController(
      vsync: this,
      lowerBound: 0,
      upperBound: 2, // noiseWidth,
      duration: _audioDuration,
    );

    ///
    _controller!.addListener(() {
      if (_controller!.isCompleted) {
        _controller!.reset();

        setState(() {});
      }
    });
    _setAnimationConfiguration(_audioDuration!);
  }

  void _setAnimationConfiguration(Duration audioDuration) async {
    // setState(() {
    //   _remainingTime = widget.formatDuration!(audioDuration);
    // });
    // debugPrint("_setAnimationConfiguration $_remainingTime");
    _completeAnimationConfiguration();
  }

  void _completeAnimationConfiguration() =>
      // setState(() => _audioConfigurationDone = true);
      setState(() {});

  _onChangeSlider(double d) async {
    // if (widget.player.playing) _changePlayingStatus();
    duration = d.round();
    // _controller?.value = (noiseWidth) * duration / maxDurationForSlider;
    _controller?.value = (2) * duration / maxDurationForSlider;
    // _remainingTime = widget.formatDuration!(_audioDuration!);
    await widget.player.seek(Duration(milliseconds: duration));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final view = View.of(context);
    final size = MediaQueryData.fromView(view).size;
    final double noiseWidth = 28.5 * (size.width / 100);
    final ThemeData theme = Theme.of(context);
    final newTHeme = theme.copyWith(
      sliderTheme: SliderThemeData(
        trackShape: CustomTrackShape(),
        thumbShape: SliderComponentShape.noThumb,
        minThumbSeparation: 0,
      ),
    );
    return Theme(
      data: newTHeme,
      child: SizedBox(
        height: 6.5 * (size.height / 100),
        width: noiseWidth,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            widget.me ? const Noises(Colors.white) : const Noises(Colors.grey),
            //if (_audioConfigurationDone)
            AnimatedBuilder(
              animation: CurvedAnimation(
                  parent:
                      _controller ?? AnimationController.unbounded(vsync: this),
                  curve: Curves.ease),
              builder: (context, child) {
                return Positioned(
                  left: _controller?.value ?? 0,
                  child: Container(
                    width: noiseWidth,
                    height: 12, // 6.w(),
                    color: widget.me
                        ? Colors.white.withOpacity(.4)
                        : Colors.grey.withOpacity(.35),
                  ),
                );
              },
            ),
            Opacity(
              opacity: .0,
              child: Container(
                width: noiseWidth,
                color: Colors.amber.withOpacity(0),
                child: Slider(
                  min: 0.0,
                  max: maxDurationForSlider,
                  onChangeStart: (__) async {
                    await widget.player.pause();
                    _controller!.stop();
                  },
                  onChanged: (_) => _onChangeSlider(_),
                  value: duration + .0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Noises extends StatelessWidget {
  final Color color;
  const Noises(this.color, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final view = View.of(context);
    final size = MediaQueryData.fromView(view).size;
    final double height =
        5.74 * (size.width / 100) * math.Random().nextDouble() +
            .26 * (size.width / 100);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (int i = 0; i < 27; i++)
          Container(
            margin: EdgeInsets.symmetric(horizontal: .2 * (size.width / 100)),
            width: .56 * (size.width / 100),
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(1000),
              color: Colors.white,
            ),
          )
      ],
    );
  }
}

class CustomTrackShape extends RoundedRectSliderTrackShape {
  ///
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    const double trackHeight = 10;
    final double trackLeft = offset.dx,
        trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}
