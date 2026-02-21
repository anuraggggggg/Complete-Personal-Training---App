import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class WarmupVideoPreview extends StatefulWidget {
  final String videoUrl;
  final bool isPlaying;

  const WarmupVideoPreview({
    super.key,
    required this.videoUrl,
    required this.isPlaying,
  });

  @override
  State<WarmupVideoPreview> createState() => _WarmupVideoPreviewState();
}

class _WarmupVideoPreviewState extends State<WarmupVideoPreview>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _controller;

  late final AnimationController _animCtrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    /// 🎬 Entry animation
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fade = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOut,
    );

    _scale = Tween<double>(begin: 1.06, end: 1.0).animate(
      CurvedAnimation(
        parent: _animCtrl,
        curve: Curves.easeOutBack,
      ),
    );

    _initVideo();
  }

  Future<void> _initVideo() async {
    if (widget.videoUrl.isEmpty) return;

    final controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );

    await controller.initialize();
    controller
      ..setLooping(true)
      ..setVolume(0)
      ..play();

    if (!mounted) {
      controller.dispose();
      return;
    }

    setState(() {
      _controller = controller;
    });

    _animCtrl.forward();
  }

  @override
  void didUpdateWidget(covariant WarmupVideoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);

    final c = _controller;
    if (c == null || !c.value.isInitialized) return;

    widget.isPlaying ? c.play() : c.pause();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;

    /// 🟡 Loading placeholder (square)
    if (c == null || !c.value.isInitialized) {
      return const AspectRatio(
        aspectRatio: 1,
        child: ColoredBox(color: Colors.black),
      );
    }

    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: AspectRatio(
          aspectRatio: 1, // ✅ PERFECT SQUARE
          child: ClipRect(
            child: Stack(
              fit: StackFit.expand,
              children: [
                /// 🎥 VIDEO (cover fit)
                FittedBox(
                  
                  child: SizedBox(
                    width: c.value.size.width,
                    height: c.value.size.height,
                    child: VideoPlayer(c),
                  ),
                ),

                /// 🌑 SUBTLE DEPTH (NO BUTTONS)
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Color(0x66000000),
                        Color(0x22000000),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
