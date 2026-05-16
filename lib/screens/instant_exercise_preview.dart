import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mighty_fitness/main.dart';
import 'package:mighty_fitness/screens/flutter_cache_manager.dart';
import 'package:better_player_plus/src/video_player/video_player.dart' as bp;

class InstantExercisePreview extends StatefulWidget {
  final String url;

  const InstantExercisePreview({
    super.key,
    required this.url,
  });

  @override
  State<InstantExercisePreview> createState() => _InstantExercisePreviewState();
}

class _InstantExercisePreviewState extends State<InstantExercisePreview>
    with WidgetsBindingObserver, RouteAware {
  bp.VideoPlayerController? _vpController;
  bool _routeSubscribed = false;

  bool get _isVideo {
    final path = _mediaPath(widget.url);
    return path.endsWith('.mp4') ||
        path.endsWith('.webm') ||
        path.endsWith('.m3u8');
  }

  String _mediaPath(String rawUrl) {
    final uri = Uri.tryParse(rawUrl.trim());
    if (uri != null && uri.path.isNotEmpty) {
      return uri.path.toLowerCase();
    }
    return rawUrl.toLowerCase();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initPreview();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeSubscribed) return;

    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
      _routeSubscribed = true;
    }
  }

  @override
  void didUpdateWidget(covariant InstantExercisePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url == widget.url) return;

    unawaited(_releaseVideoController());
    _initPreview();
  }

  void _initPreview() {
    if (widget.url.isEmpty) return;

    if (_isVideo) {
      _initVideo();
    }
  }

  Future<void> _initVideo() async {
    if (_vpController != null) return;

    final controller = bp.VideoPlayerController();
    _vpController = controller;
    await controller.setNetworkDataSource(widget.url);

    if (!mounted || _vpController != controller) {
      await controller.dispose();
      return;
    }

    await controller.setLooping(true);
    await controller.setVolume(0);
    await controller.play();

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _releaseVideoController() async {
    final controller = _vpController;
    _vpController = null;

    if (controller == null) return;

    try {
      await controller.pause();
    } catch (_) {}

    try {
      await controller.dispose();
    } catch (_) {}

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_routeSubscribed) {
      routeObserver.unsubscribe(this);
    }
    unawaited(_releaseVideoController());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.url.isEmpty) return _placeholder();

    final screenWidth = MediaQuery.of(context).size.width;
    final thumbSize = (screenWidth * 0.22).clamp(72.0, 96.0);

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: thumbSize,
          height: thumbSize,
          child: _isVideo ? _videoView() : _gifView(),
        ),
      ),
    );
  }

  Widget _videoView() {
    final controller = _vpController;
    if (controller == null || !controller.value.initialized) {
      return _skeleton();
    }

    final size = controller.value.size;
    if (size == null) return _skeleton();

    return Center(
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: bp.VideoPlayer(controller),
        ),
      ),
    );
  }

  Widget _gifView() {
    return Image(
      image: CachedNetworkImageProvider(
        widget.url,
        cacheManager: FastGifCacheManager.instance,
      ),
      fit: BoxFit.cover,
      filterQuality: FilterQuality.low,
      gaplessPlayback: true,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) return child;
        return _skeleton();
      },
      errorBuilder: (_, __, ___) => _placeholder(),
    );
  }

  Widget _skeleton() {
    return Container(color: Colors.grey.shade900);
  }

  Widget _placeholder() {
    return Container(
      color: Colors.grey.shade900,
      alignment: Alignment.center,
      child: const Icon(
        Icons.fitness_center,
        size: 16,
        color: Colors.white54,
      ),
    );
  }

  @override
  void didPushNext() {
    if (_isVideo) {
      unawaited(_releaseVideoController());
    }
  }

  @override
  void didPopNext() {
    if (_isVideo && _vpController == null) {
      _initPreview();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isVideo) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      unawaited(_releaseVideoController());
    } else if (state == AppLifecycleState.resumed && _vpController == null) {
      _initPreview();
    }
  }
}
