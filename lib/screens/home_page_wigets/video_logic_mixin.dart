import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

mixin VideoLogicMixin<T extends StatefulWidget> on State<T> {
  YoutubePlayerController? ytController;

  Duration get currentPosition =>
      ytController?.value.position ?? Duration.zero;

  Duration get currentDuration =>
      ytController?.metadata.duration ?? Duration.zero;

  double get currentProgress {
    final d = currentDuration;
    if (d == Duration.zero) return 0;
    return currentPosition.inMilliseconds / d.inMilliseconds;
  }

  void togglePlayPause({VoidCallback? onPause}) {
    final c = ytController;
    if (c == null) return;

    if (c.value.isPlaying) {
      c.pause();
      onPause?.call();
    } else {
      c.play();
    }

    HapticFeedback.selectionClick();
  }

  void seekRelative(Duration offset) {
    final c = ytController;
    if (c == null) return;

    final dur = c.metadata.duration;
    if (dur == Duration.zero) return;

    final current = c.value.position;
    Duration target = current + offset;

    if (target < Duration.zero) target = Duration.zero;
    if (target > dur) target = dur;

    c.seekTo(target);
    HapticFeedback.selectionClick();
  }

  void setVolume(double v) {
    final c = ytController;
    if (c == null) return;

    final vol = v.clamp(0.0, 1.0);
    c.setVolume((vol * 100).toInt());
  }

  void disposeVideoController() {
    try {
      ytController?.pause();
      ytController?.dispose();
      ytController = null;
    } catch (_) {}
  }
}
