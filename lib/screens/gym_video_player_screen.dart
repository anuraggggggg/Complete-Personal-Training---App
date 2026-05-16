import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:mighty_fitness/features/all_gym_video/viewmodels/all_gym_video_view_model.dart';

class GymVideoPlayerScreen extends StatefulWidget {
  final String title;
  final String trainer;
  final String videoId;
  final String thumbnail;

  const GymVideoPlayerScreen({
    super.key,
    required this.title,
    required this.trainer,
    required this.videoId,
    required this.thumbnail,
  });

  @override
  State<GymVideoPlayerScreen> createState() => _GymVideoPlayerScreenState();
}

class _GymVideoPlayerScreenState extends State<GymVideoPlayerScreen> {
  late VideoPlayerController _vp;

  final AllGymVideoViewModel vm = Get.find<AllGymVideoViewModel>();

  bool showUI = true;
  bool hasError = false;

  int? _selectedResolution;
  Timer? hideTimer;

  Duration position = Duration.zero;
  Duration duration = Duration.zero;

  // ================= INIT =================
  @override
  void initState() {
    super.initState();
    _selectedResolution = vm.selectedResolution.value;
    _initPlayer(widget.videoId);
  }

  Future<void> _initPlayer(String url) async {
    _vp = VideoPlayerController.networkUrl(
      Uri.parse(url),
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: false,
        allowBackgroundPlayback: false,
      ),
    );

    try {
      await _vp.initialize();
      if (!mounted) return;

      duration = _vp.value.duration;

      _vp
        ..setLooping(true) // 🔁 reels style loop
        ..setVolume(1.0)
        ..play();

      _vp.addListener(_listener);

      _hideUI();
      setState(() {});
    } catch (_) {
      setState(() => hasError = true);
    }
  }

  void _listener() {
    if (!mounted || !_vp.value.isInitialized) return;

    setState(() {
      position = _vp.value.position;
      duration = _vp.value.duration;
    });

    if (_vp.value.playbackSpeed != 1.0) {
      _vp.setPlaybackSpeed(1.0);
    }
  }

  void _hideUI() {
    hideTimer?.cancel();
    hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => showUI = false);
    });
  }

  @override
  void dispose() {
    hideTimer?.cancel();
    _vp.dispose();
    super.dispose();
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          // Tap anywhere → play / pause
          if (_vp.value.isPlaying) {
            _vp.pause();
          } else {
            _vp.play();
          }
          setState(() => showUI = true);
          _hideUI();
        },
        child: Stack(
          children: [
            /// 🎥 FULL SCREEN VIDEO
            Positioned.fill(
              child: hasError
                  ? const Center(
                      child: Text(
                        "Unable to play video",
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  : _vp.value.isInitialized
                      ? FittedBox(
                          fit: BoxFit.contain,
                          child: SizedBox(
                            width: _vp.value.size.width,
                            height: _vp.value.size.height,
                            child: VideoPlayer(_vp),
                          ),
                        )
                      : const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        ),
            ),

            /// 🔝 TOP BAR
            if (showUI)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          CupertinoIcons.back,
                          color: Colors.white,
                        ),
                        onPressed: () => Get.back(),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(
                          CupertinoIcons.settings,
                          color: Colors.white,
                        ),
                        onPressed: _showQualitySheet,
                      ),
                    ],
                  ),
                ),
              ),

            /// 👉 RIGHT SIDE REELS CONTROLS
            if (showUI)
              Positioned(
                right: 14,
                bottom: 120,
                child: Column(
                  children: [
                    /// ⏪ REVERSE 5 SEC
                    _reelIcon(
                      icon: CupertinoIcons.gobackward_15,
                      onTap: () {
                        final back = position - const Duration(seconds: 5);
                        _vp.seekTo(
                          back > Duration.zero ? back : Duration.zero,
                        );
                      },
                    ),

                    const SizedBox(height: 18),

                    /// ▶️ PLAY / PAUSE
                    _reelIcon(
                      icon: _vp.value.isPlaying
                          ? CupertinoIcons.pause
                          : CupertinoIcons.play,
                      onTap: () {
                        _vp.value.isPlaying ? _vp.pause() : _vp.play();
                        setState(() {});
                        _hideUI();
                      },
                    ),
                  ],
                ),
              ),

            /// 📝 BOTTOM TEXT
            if (showUI)
              Positioned(
                left: 14,
                right: 90,
                bottom: 30,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (widget.trainer.isNotEmpty)
                      Text(
                        "Coach: ${widget.trainer}",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),

            /// ⚪ BOTTOM WHITE PROGRESS (INSTAGRAM STYLE)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: LinearProgressIndicator(
                value: duration.inMilliseconds == 0
                    ? 0
                    : position.inMilliseconds / duration.inMilliseconds,
                backgroundColor: Colors.white.withOpacity(0.25),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 2.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= REEL ICON =================
  Widget _reelIcon({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        width: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.55),
        ),
        child: Icon(icon, color: Colors.white, size: 26),
      ),
    );
  }

  // ================= QUALITY SHEET =================
  void _showQualitySheet() {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Text(
              "Quality",
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _qualityTile("Auto", _selectedResolution == null, () {
              Get.back();
              _changeQuality(null);
            }),
            ...vm.availableResolutions.map(
              (res) => _qualityTile(
                "${res}p",
                _selectedResolution == res,
                () {
                  Get.back();
                  _changeQuality(res);
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _qualityTile(String label, bool selected, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      title: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      trailing: selected ? const Icon(Icons.check, color: Colors.white) : null,
    );
  }

  Future<void> _changeQuality(int? res) async {
    if (_selectedResolution == res) return;

    _selectedResolution = res;

    await vm.changeVideoQuality(resolution: res);
    if (vm.exerciseList.isEmpty) {
      Get.snackbar(
        "Video",
        "No video available for selected quality",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final newUrl = vm.resolveVideoUrl(vm.exerciseList.first);
    if (newUrl.trim().isEmpty) {
      Get.snackbar(
        "Video",
        "Unable to load selected quality",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    await _vp.pause();
    await _vp.dispose();
    await _initPlayer(newUrl);
  }
}

