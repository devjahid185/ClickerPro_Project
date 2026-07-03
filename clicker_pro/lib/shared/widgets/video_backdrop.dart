// lib/shared/widgets/video_backdrop.dart
//
// Full-screen looping, muted, auto-playing video backdrop for brand chrome
// (the login screen). Renders a solid fallback colour until the first frame
// is ready so there is never a black flash, cover-fits the video to the
// screen (BoxFit.cover via FittedBox), and lays an optional dark scrim on top
// so foreground text stays readable.
//
// The controller is fully owned here: initialised in initState, disposed in
// dispose. Playback is silent (volume 0) and looping so it reads as ambient
// motion, not a clip that ends.

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoBackdrop extends StatefulWidget {
  const VideoBackdrop({
    super.key,
    required this.asset,
    this.fallbackColor,
    this.scrim,
  });

  /// Bundled asset path, e.g. `assets/Login/Login.mp4`.
  final String asset;

  /// Solid colour shown before the first frame decodes (and behind the video
  /// if it ever fails to load). Defaults to black.
  final Color? fallbackColor;

  /// Optional gradient/solid overlay painted over the video for legibility.
  final Widget? scrim;

  @override
  State<VideoBackdrop> createState() => _VideoBackdropState();
}

class _VideoBackdropState extends State<VideoBackdrop> {
  late final VideoPlayerController _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(widget.asset)
      ..setLooping(true)
      ..setVolume(0);
    _controller.initialize().then((_) {
      if (!mounted) return;
      _controller.play();
      setState(() => _ready = true);
    }).catchError((_) {
      // Leave _ready false — the fallback colour stays, no crash.
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fallback = widget.fallbackColor ?? Colors.black;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: fallback),
        if (_ready)
          FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: _controller.value.size.width,
              height: _controller.value.size.height,
              child: VideoPlayer(_controller),
            ),
          ),
        if (widget.scrim != null) widget.scrim!,
      ],
    );
  }
}
