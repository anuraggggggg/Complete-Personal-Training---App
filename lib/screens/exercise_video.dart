import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'dart:typed_data';



class ExerciseVideo extends StatefulWidget {
  final String videoPath;
  final Map<String, VideoPlayerController> cachedVideos;

  const ExerciseVideo({
    required this.videoPath,
    required this.cachedVideos,
    Key? key,
  }) : super(key: key);

  @override
  State<ExerciseVideo> createState() => _ExerciseVideoState();
}

class _ExerciseVideoState extends State<ExerciseVideo> {
  VideoPlayerController? _controller;
  Uint8List? _thumbnail;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
    _initializeVideo();
  }


  Future<void> _loadThumbnail() async {
    try {
      final uint8list = await VideoThumbnail.thumbnailData(
        video: widget.videoPath,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 200,
        quality: 70,
      );
      if (mounted) setState(() => _thumbnail = uint8list);
    } catch (e) {
      debugPrint("Thumbnail generation failed: $e");
    }
  }


  Future<void> _initializeVideo() async {
    if (widget.cachedVideos.containsKey(widget.videoPath)) {
      _controller = widget.cachedVideos[widget.videoPath]!;
      await _controller!.setLooping(true);
      await _controller!.setVolume(0);
      await _controller!.setPlaybackSpeed(1.5);

      if (_controller!.value.isInitialized) {
        await _controller!.seekTo(const Duration(milliseconds: 100));
        _controller!.play();
      }
    } else {
      _controller = VideoPlayerController.network(widget.videoPath);
      await _controller!.initialize();
      await _controller!
        ..setLooping(true)
        ..setVolume(0)
        ..setPlaybackSpeed(1.5)
        ..seekTo(const Duration(milliseconds: 100))
        ..play();

      widget.cachedVideos[widget.videoPath] = _controller!;
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller != null && _controller!.value.isInitialized) {
      return AspectRatio(
        aspectRatio: _controller!.value.aspectRatio,
        child: VideoPlayer(_controller!),
      );
    } else if (_thumbnail != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.memory(
          _thumbnail!,
          fit: BoxFit.cover,
          height: double.infinity,
          width: double.infinity,
        ),
      );
    } else {
      return const Center(
        child: CupertinoActivityIndicator(color: Colors.white),
      );
    }
  }

  @override
  void dispose() {
    
    super.dispose();
  }
}
