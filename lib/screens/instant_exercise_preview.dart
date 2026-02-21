import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
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
    with AutomaticKeepAliveClientMixin {
  bp.VideoPlayerController? _vpController;
  FileImage? _gifFileImage;
  bool _gifLoading = false;

  bool get _isVideo {
    final lowerUrl = widget.url.toLowerCase();
    return lowerUrl.endsWith('.mp4') ||
        lowerUrl.endsWith('.webm') ||
        lowerUrl.endsWith('.m3u8');
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initPreview();
  }

  @override
  void didUpdateWidget(covariant InstantExercisePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url == widget.url) return;

    _vpController?.dispose();
    _vpController = null;
    _gifFileImage = null;
    _gifLoading = false;
    _initPreview();
  }

  void _initPreview() {
    if (widget.url.isEmpty) return;

    if (_isVideo) {
      _initVideo();
    } else {
      _initGif();
    }
  }

  Future<void> _initVideo() async {
    _vpController = bp.VideoPlayerController();
    await _vpController!.setNetworkDataSource(widget.url);

    if (!mounted || _vpController == null) return;

    await _vpController!.setLooping(true);
    await _vpController!.setVolume(0);
    await _vpController!.play();

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _initGif() async {
    if (_gifLoading) return;

    _gifLoading = true;
    try {
      final FileInfo fileInfo =
          await FastGifCacheManager.instance.downloadFile(widget.url);

      if (!mounted) return;

      final imageProvider = FileImage(fileInfo.file);
      await precacheImage(imageProvider, context);

      if (!mounted) return;
      setState(() {
        _gifFileImage = imageProvider;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _gifFileImage = null;
      });
    } finally {
      _gifLoading = false;
    }
  }

  @override
  void dispose() {
    _vpController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

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
    if (_gifFileImage != null) {
      return Image(
        image: _gifFileImage!,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.low,
        gaplessPlayback: true,
      );
    }

    return CachedNetworkImage(
      cacheManager: FastGifCacheManager.instance,
      imageUrl: widget.url,
      fit: BoxFit.cover,
      placeholder: (_, __) => _skeleton(),
      errorWidget: (_, __, ___) => _placeholder(),
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      placeholderFadeInDuration: Duration.zero,
      useOldImageOnUrlChange: true,
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
}
