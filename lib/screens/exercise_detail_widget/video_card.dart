import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mighty_fitness/models/home_page_workout_list_request.dart';
import 'package:video_player/video_player.dart';


class VideoCard extends StatefulWidget {
  final Exercises exercise;
  final String? overrideVideo;

  const VideoCard({
    super.key,
    required this.exercise,
    this.overrideVideo,
  });

  @override
  State<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard>
    with TickerProviderStateMixin {
  VideoPlayerController? _vp;

  bool _isLoading = true;
  bool _controlsVisible = true;
  bool _isPlaying = false;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  Timer? _hideTimer;
  Timer? _ticker;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  // ================= INIT =================
@override
void initState() {
  super.initState();

  _enterImmersiveMode(); // 🔥 ADD THIS

  _fadeCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  _fadeAnim = CurvedAnimation(
    parent: _fadeCtrl,
    curve: Curves.easeInOut,
  );

  _initPlayer(_resolveVideo());
}

Future<void> _enterImmersiveMode() async {
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
  );
}

Future<void> _exitImmersiveMode() async {
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );
}

Future<void> _exitPlayer() async {
  await _exitImmersiveMode();
  if (!mounted) return;
  Navigator.of(context).pop();
}




  // ================= VIDEO SOURCE =================
  String _resolveVideo() {
    if (widget.overrideVideo?.isNotEmpty == true) {
      return widget.overrideVideo!;
    }
    if (widget.exercise.selectedVideoUrl?.isNotEmpty == true) {
      return widget.exercise.selectedVideoUrl!;
    }
    for (final v in widget.exercise.exerciseVideos) {
      if (v.hlsMasterUrl?.isNotEmpty == true) return v.hlsMasterUrl!;
      if (v.videoUrl?.isNotEmpty == true) return v.videoUrl!;
    }
    return "";
  }

  // ================= PLAYER =================
  Future<void> _initPlayer(String url) async {
    if (url.isEmpty) return;

    await _vp?.dispose();

    setState(() => _isLoading = true);

    final controller =
        VideoPlayerController.networkUrl(Uri.parse(url));
    await controller.initialize();

    controller
      ..setLooping(true)
      ..play();

    _vp = controller;
    _isPlaying = true;
    _isLoading = false;

    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 300), (_) {
      if (!mounted || _vp == null) return;
      setState(() {
        _position = _vp!.value.position;
        _duration = _vp!.value.duration;
      });
    });

    _showControlsTemporarily();
    _fadeCtrl.forward();
    setState(() {});
  }

  // ================= CONTROLS =================
  void _togglePlay() {
    if (_vp == null) return;

    HapticFeedback.selectionClick();

    _vp!.value.isPlaying ? _vp!.pause() : _vp!.play();
    setState(() => _isPlaying = _vp!.value.isPlaying);
    _showControlsTemporarily();
  }

  void _showControlsTemporarily() {
    _hideTimer?.cancel();
    _controlsVisible = true;
    _fadeCtrl.forward();

    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      _controlsVisible = false;
      _fadeCtrl.reverse();
      setState(() {});
    });
  }

  void _seekRelative(int seconds) {
    if (_vp == null) return;
    _vp!.seekTo(_position + Duration(seconds: seconds));
    _showControlsTemporarily();
  }

  void _seekTo(double v) {
    if (_duration == Duration.zero) return;
    _vp?.seekTo(
      Duration(
        milliseconds: (_duration.inMilliseconds * v).toInt(),
      ),
    );
  }

  String _fmt(Duration d) =>
      "${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}";

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final safe = MediaQuery.of(context).padding;

    return  WillPopScope(
  onWillPop: () async {
    await _exitImmersiveMode();
    return true;
  },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            /// VIDEO (Instagram style – NO STRETCH)
            if (_vp != null && _vp!.value.isInitialized)
              Positioned.fill(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _vp!.value.size.width,
                    height: _vp!.value.size.height,
                    child: VideoPlayer(_vp!),
                  ),
                ),
              ),
      
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
      
            /// TAP AREA
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _showControlsTemporarily,
              ),
            ),
      
            /// TOP BAR
         Positioned(
  top: safe.top + 10,
  left: 16,
  right: 16,
  child: Row(
    children: [
      /// 🔙 BACK BUTTON
      GestureDetector(
        onTap: _exitPlayer,
        behavior: HitTestBehavior.opaque,
        child: const Padding(
          padding: EdgeInsets.all(6),
          child: Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: Colors.white,
          ),
        ),
      ),

      const Spacer(),

      Text(
        "Warmup",
        style: GoogleFonts.montserrat(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),

      const Spacer(),

      /// ❌ CLOSE BUTTON
      GestureDetector(
        onTap: _exitPlayer,
        behavior: HitTestBehavior.opaque,
        child: const Padding(
          padding: EdgeInsets.all(6),
          child: Icon(
            Icons.close,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    ],
  ),
),

      
            /// CENTER PLAY
            if (!_isPlaying && !_isLoading)
              Center(
                child: GestureDetector(
                  onTap: _togglePlay,
                  child: Container(
                    width: 78,
                    height: 78,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.black,
                      size: 38,
                    ),
                  ),
                ),
              ),
      
            /// BOTTOM INFO
            Positioned(
              left: 20,
              right: 20,
              bottom: 120,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
               
                  Text(
                    widget.exercise.title ??
                        "Mindfulness for beginners",
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
      
            /// 🔥 PREMIUM CONTROL BAR
            if (_controlsVisible)
              Positioned(
                left: 14,
                right: 14,
                bottom: 22,
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: BackdropFilter(
                      filter:
                          ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        padding:
                            const EdgeInsets.fromLTRB(14, 14, 14, 12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.08),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.45),
                              blurRadius: 30,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            /// PROGRESS
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 3,
                                thumbShape:
                                    const RoundSliderThumbShape(
                                        enabledThumbRadius: 6),
                                activeTrackColor: Colors.white,
                                inactiveTrackColor: Colors.white24,
                                thumbColor: Colors.white,
                              ),
                              child: Slider(
                                value: _duration.inMilliseconds == 0
                                    ? 0
                                    : _position.inMilliseconds /
                                        _duration.inMilliseconds,
                                onChanged: _seekTo,
                              ),
                            ),
      
                            const SizedBox(height: 6),
      
                            /// CONTROLS
                            Row(
                              children: [
                                Text(
                                  _fmt(_position),
                                  style: GoogleFonts.montserrat(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                                const Spacer(),
                                _roundIconBtn(
                                  Icons.replay_10,
                                  () => _seekRelative(-10),
                                ),
                                const SizedBox(width: 12),
                                GestureDetector(
                                  onTap: _togglePlay,
                                  child: Container(
                                    width: 54,
                                    height: 54,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                    ),
                                    child: Icon(
                                      _isPlaying
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                      color: Colors.black,
                                      size: 32,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                _roundIconBtn(
                                  Icons.forward_10,
                                  () => _seekRelative(10),
                                ),
                                const Spacer(),
                                Text(
                                  _fmt(_duration),
                                  style: GoogleFonts.montserrat(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _roundIconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.12),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _ticker?.cancel();
    _fadeCtrl.dispose();
    _vp?.dispose();
    super.dispose();
  }
}
