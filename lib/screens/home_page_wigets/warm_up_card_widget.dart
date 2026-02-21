import 'dart:async';
import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AnimatedWarmupCard extends StatefulWidget {
  final String video;
  final VoidCallback onTap;

  const AnimatedWarmupCard({
    super.key,
    required this.video,
    required this.onTap,
  });

  @override
  State<AnimatedWarmupCard> createState() => _AnimatedWarmupCardState();
}

class _AnimatedWarmupCardState extends State<AnimatedWarmupCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _glow;
  late Key _previewKey;

  @override
  void initState() {
    super.initState();

    _pulse = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _glow = Tween<double>(begin: 0.25, end: 0.55).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );

    _previewKey = ValueKey(widget.video);
  }

  @override
  void didUpdateWidget(covariant AnimatedWarmupCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.video != widget.video) {
      _previewKey = ValueKey(widget.video);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glow,
      builder: (_, __) {
        return InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFD31939).withValues(alpha: _glow.value),
                    const Color(0xFF7A0012),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.redAccent.withValues(alpha: _glow.value * 0.6),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _warmupBadge(),
                        const SizedBox(height: 10),
                        _titleText(),
                        const SizedBox(height: 4),
                        _subText(),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 105,
                      height: 95,
                      child: _WarmupBetterPlayerPreview(
                        key: _previewKey,
                        videoUrl: widget.video,
                        isPlaying: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _warmupBadge() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.20),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.local_fire_department,
              color: Colors.orangeAccent,
              size: 16,
            ),
            SizedBox(width: 4),
            Text(
              'Warm Up',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );

  Widget _titleText() => Text(
        "Let's Get Started!",
        style: GoogleFonts.montserrat(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      );

  Widget _subText() => Text(
        'Prepare your body',
        style: GoogleFonts.montserrat(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 12,
        ),
      );
}

class _WarmupBetterPlayerPreview extends StatefulWidget {
  final String videoUrl;
  final bool isPlaying;

  const _WarmupBetterPlayerPreview({
    super.key,
    required this.videoUrl,
    required this.isPlaying,
  });

  @override
  State<_WarmupBetterPlayerPreview> createState() =>
      _WarmupBetterPlayerPreviewState();
}

class _WarmupBetterPlayerPreviewState
    extends State<_WarmupBetterPlayerPreview> {
  BetterPlayerController? _controller;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    if (widget.videoUrl.isEmpty) return;

    final controller = BetterPlayerController(
      const BetterPlayerConfiguration(
        autoPlay: true,
        looping: true,
        fit: BoxFit.cover,
        aspectRatio: 1,
        controlsConfiguration: BetterPlayerControlsConfiguration(
          showControls: false,
          enableSkips: false,
          enableFullscreen: false,
          enablePlayPause: false,
          enableMute: false,
          enablePlaybackSpeed: false,
          enableProgressText: false,
          enableProgressBar: false,
          enableProgressBarDrag: false,
          enableOverflowMenu: false,
          enableSubtitles: false,
          enableQualities: false,
          enableAudioTracks: false,
          enablePip: false,
        ),
      ),
    );

    try {
      await controller.setupDataSource(
        BetterPlayerDataSource(
          BetterPlayerDataSourceType.network,
          widget.videoUrl,
        ),
      );
      await controller.setVolume(0);

      if (widget.isPlaying) {
        await controller.play();
      } else {
        await controller.pause();
      }

      if (!mounted) {
        controller.dispose(forceDispose: true);
        return;
      }

      setState(() {
        _controller = controller;
        _hasError = false;
      });
    } catch (_) {
      controller.dispose(forceDispose: true);
      if (!mounted) return;
      setState(() {
        _hasError = true;
      });
    }
  }

  @override
  void didUpdateWidget(covariant _WarmupBetterPlayerPreview oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.videoUrl != widget.videoUrl) {
      _controller?.dispose(forceDispose: true);
      _controller = null;
      _hasError = false;
      unawaited(_initPlayer());
      return;
    }

    final controller = _controller;
    if (controller == null || oldWidget.isPlaying == widget.isPlaying) return;

    if (widget.isPlaying) {
      unawaited(controller.play());
    } else {
      unawaited(controller.pause());
    }
  }

  @override
  void dispose() {
    _controller?.dispose(forceDispose: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return const ColoredBox(color: Colors.black);
    }

    final controller = _controller;
    if (controller == null) {
      return const ColoredBox(color: Colors.black);
    }

    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        fit: StackFit.expand,
        children: [
          BetterPlayer(controller: controller),
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
    );
  }
}
