import 'dart:async';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class ExerciseVideoController {
  YoutubePlayerController? controller;

  Future<void> init(String raw) async {
    final id = YoutubePlayer.convertUrlToId(raw) ?? raw;

    controller = YoutubePlayerController(
      initialVideoId: id,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        hideControls: true,
        useHybridComposition: true,
      ),
    );
  }

  Future<void> switchVideo(String raw) async {
    final id = YoutubePlayer.convertUrlToId(raw) ?? raw;
    HapticFeedback.mediumImpact();

    await dispose();
    await Future.delayed(const Duration(milliseconds: 120));
    await init(id);
  }

  Future<void> dispose() async {
    try {
      controller?.pause();
      controller?.dispose();
      controller = null;
    } catch (_) {}
  }
}
