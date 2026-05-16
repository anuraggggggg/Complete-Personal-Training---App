import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class DebugVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const DebugVideoPlayer({super.key, required this.videoUrl});

  @override
  State<DebugVideoPlayer> createState() => _DebugVideoPlayerState();
}

class _DebugVideoPlayerState extends State<DebugVideoPlayer> {
  late VideoPlayerController _videoCtrl;
  ChewieController? _chewieCtrl;

  @override
  void initState() {
    super.initState();

    debugPrint("🎬 DEBUG PLAYER URL: ${widget.videoUrl}");

    _videoCtrl = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
    );

    _videoCtrl.initialize().then((_) {
      debugPrint("✅ Video initialized");
      setState(() {
        _chewieCtrl = ChewieController(
          videoPlayerController: _videoCtrl,
          autoPlay: true,
          looping: false,
          allowFullScreen: true,
          showControls: true,
        );
      });
    }).catchError((e) {
      debugPrint("❌ Video init error: $e");
    });
  }

  @override
  void dispose() {
    _chewieCtrl?.dispose();
    _videoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Debug Player"),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Get.back(),
        ),
      ),
      body: Center(
        child: _chewieCtrl != null
            ? Chewie(controller: _chewieCtrl!)
            : const CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}
