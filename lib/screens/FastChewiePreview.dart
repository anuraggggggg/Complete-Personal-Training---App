import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class FastChewiePreview extends StatefulWidget {
  final String url;

  const FastChewiePreview({super.key, required this.url});

  @override
  State<FastChewiePreview> createState() => _FastChewiePreviewState();
}

class _FastChewiePreviewState extends State<FastChewiePreview> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool ready = false;

  // ---------- VIDEO POOL ----------
  static final Map<String, VideoPlayerController> _pool = {};
  static const int _maxPool = 5;

  bool get _isYoutube {
    return widget.url.length == 11 ||
        widget.url.contains('youtube') ||
        widget.url.contains('youtu.be');
  }

  String get _youtubeId {
    if (widget.url.length == 11) return widget.url;
    return YoutubePlayer.convertUrlToId(widget.url) ?? "";
  }

  @override
  void initState() {
    super.initState();
    if (!_isYoutube) {
      _initMp4Preview();
    }
  }

  // ------------------------------------------------
  // MP4 / FILE → REAL AUTO LOOP (GIF STYLE)
  // ------------------------------------------------
  Future<void> _initMp4Preview() async {
    try {
      if (_pool.containsKey(widget.url)) {
        _videoController = _pool[widget.url];
      } else {
        if (_pool.length >= _maxPool) {
          final oldKey = _pool.keys.first;
          _pool[oldKey]!.dispose();
          _pool.remove(oldKey);
        }

        final file = await DefaultCacheManager().getSingleFile(widget.url);

        _videoController = VideoPlayerController.file(file);
        await _videoController!.initialize();

        _videoController!
          ..setLooping(true)
          ..setVolume(0);

        _pool[widget.url] = _videoController!;
      }

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: true,
        showControls: false,      // ❌ no play/pause
        allowFullScreen: false,
        allowMuting: false,
        aspectRatio: _videoController!.value.aspectRatio,
      );

      setState(() => ready = true);
    } catch (e) {
      debugPrint("Preview error: $e");
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    super.dispose();
  }

  // ------------------------------------------------
  // UI
  // ------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 95,
        height: 120,
        child: _isYoutube ? _youtubeGifLikePreview() : _mp4Preview(),
      ),
    );
  }

  // ------------------------------------------------
  // YOUTUBE → GIF-LIKE (NO PLAY, NO TAP)
  // ------------------------------------------------
  Widget _youtubeGifLikePreview() {
    if (_youtubeId.isEmpty) return _loader();

    return Image.network(
      "https://img.youtube.com/vi/$_youtubeId/hqdefault.jpg",
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
  }

  // ------------------------------------------------
  // MP4 PREVIEW
  // ------------------------------------------------
  Widget _mp4Preview() {
    return ready
        ? Chewie(controller: _chewieController!)
        : _loader();
  }

  Widget _loader() {
    return const Center(
      child: SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 1.2,
          color: Colors.white,
        ),
      ),
    );
  }
}
