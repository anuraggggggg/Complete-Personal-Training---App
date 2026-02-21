import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:mighty_fitness/models/cuircuite_exercise_model.dart';


class CircuitExerciseDetailScreen extends StatefulWidget {
  final Exercise exercise;
  final int index;

  const CircuitExerciseDetailScreen({
    super.key,
    required this.exercise,
    required this.index,
  });

  @override
  State<CircuitExerciseDetailScreen> createState() =>
      _CircuitExerciseDetailScreenState();
}

class _CircuitExerciseDetailScreenState
    extends State<CircuitExerciseDetailScreen> {
  late VideoPlayerController _controller;

  bool _isFullScreen = false;
  bool _videoEnded = false;
  bool _controlsVisible = true;

Timer? _hideTimer;


void _toggleControls() {
  setState(() => _controlsVisible = !_controlsVisible);

  _hideTimer?.cancel();
  if (_controlsVisible) {
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _controlsVisible = false);
    });
  }
}

String _format(Duration d) =>
    "${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:"
    "${d.inSeconds.remainder(60).toString().padLeft(2, '0')}";



  @override
  void initState() {
    super.initState();

    final String? rawUrl =
        widget.exercise.selectedVideoUrl ??
            (widget.exercise.exerciseVideos?.isNotEmpty == true
                ? widget.exercise.exerciseVideos!.first.videoUrl
                : null);

    _controller = VideoPlayerController.networkUrl(
      Uri.parse(rawUrl ?? ""),
    )
      ..initialize().then((_) {
        setState(() {});
      })
      ..addListener(_playerListener);
  }

void _playerListener() {
  if (!mounted || !_controller.value.isInitialized) return;

  // 🔁 progress update (THIS IS THE FIX)
  setState(() {});

  // 🧨 video end detection
  if (_controller.value.position >= _controller.value.duration &&
      !_videoEnded) {
    _videoEnded = true;
  }
}



  Future<void> _enterFullScreen() async {
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
    );
    setState(() => _isFullScreen = true);
  }

  Future<void> _exitFullScreen() async {
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );
    setState(() => _isFullScreen = false);
  }

@override
void dispose() {
  _hideTimer?.cancel(); // 👈 ADD THIS
  _controller.removeListener(_playerListener);
  _controller.dispose();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  super.dispose();
}



  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        if (_isFullScreen) {
          await _exitFullScreen();
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: _isFullScreen
            ? null
            : AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                automaticallyImplyLeading: false,
                leading: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new,
                    size: 20,
                    color: cs.onSurface,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                title: Text(
                  "Circuit Exercise",
                  style: GoogleFonts.montserrat(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

        /// 🔥 FULL BODY SCROLL IMPLEMENTATION
        body: SafeArea(
          child: _isFullScreen
              ? _buildFullscreenVideo()
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// ================= VIDEO =================
                   Padding(
  padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
  child: Center(
    child: LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = width * (16 / 9)*0.88; 

        return SizedBox(
          width: width,
          height: height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _toggleControls,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  /// 🎥 VIDEO (Instagram crop style)
                  _controller.value.isInitialized
                      ? FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: _controller.value.size.width,
                            height: _controller.value.size.height,
                            child: VideoPlayer(_controller),
                          ),
                        )
                      : const Center(
                          child: CircularProgressIndicator(),
                        ),

                  /// ▶️ CENTER PLAY / PAUSE
                  if (_controlsVisible && !_videoEnded)
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _controller.value.isPlaying
                                ? _controller.pause()
                                : _controller.play();
                          });
                        },
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black54,
                          ),
                          child: Icon(
                            _controller.value.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 42,
                          ),
                        ),
                      ),
                    ),

                  /// 🔁 VIDEO ENDED
                  if (_videoEnded)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.9),
                        alignment: Alignment.center,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() => _videoEnded = false);
                            _controller.seekTo(Duration.zero);
                            _controller.play();
                          },
                          child: const Text("Play Again"),
                        ),
                      ),
                    ),

                  /// 🎛 BOTTOM MEDIA CONTROLS
                  if (_controlsVisible && _controller.value.isInitialized)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black87,
                            ],
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            /// PROGRESS BAR
                            Slider(
                              min: 0,
                              max: _controller
                                      .value.duration.inMilliseconds
                                      .toDouble()
                                      .clamp(1, double.infinity),
                              value: _controller
                                  .value.position.inMilliseconds
                                  .clamp(
                                    0,
                                    _controller.value.duration.inMilliseconds,
                                  )
                                  .toDouble(),
                              onChanged: (v) {
                                _controller.seekTo(
                                  Duration(milliseconds: v.toInt()),
                                );
                              },
                              activeColor: Colors.white,
                              inactiveColor: Colors.white30,
                            ),

                            /// TIME ROW
                            Row(
                              children: [
                                Text(
                                  _format(_controller.value.position),
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 12),
                                ),
                                const Spacer(),
                                Text(
                                  _format(_controller.value.duration),
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                  /// ⛶ FULLSCREEN
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: _enterFullScreen,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.fullscreen,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  ),
),



                      /// ================= CONTENT =================
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                              Row(
                          children: [
                            Container(
                              height: 30,
                              child: Image.asset('assets/title.png')),
                              SizedBox(width:  10,),
                              Text(
                          widget.exercise.title ?? "",
                          style: GoogleFonts.montserrat(
                            color: cs.onSurface,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                          ],
                        ),

                            const SizedBox(height: 20),

                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: cs.surface,
                                borderRadius:
                                    BorderRadius.circular(16),
                                border: Border.all(
                                  color: cs.onSurface
                                      .withOpacity(0.08),
                                ),
                              ),
                              child: Text(
                                widget.exercise.instruction
                                        ?.replaceAll(
                                            RegExp(r'<[^>]*>'),
                                            '') ??
                                    "No instructions available.",
                                style: GoogleFonts.montserrat(
                                   color:
                                  cs.onSurface.withOpacity(0.75),
                                  fontSize: 14,
                                  height: 1.6,
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() =>
                                      _videoEnded = false);
                                  _controller.play();
                                },
                                style:
                                    ElevatedButton.styleFrom(
                                  backgroundColor: cs.primary,
                                  shape:
                                      RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(14),
                                  ),
                                ),
                                child: Text(
                                  "Play Exercise",
                                  style: GoogleFonts.montserrat(
                                    color: Colors.white,
                                    fontWeight:
                                        FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  /// 🔥 FULLSCREEN VIEW (NO SCROLL)
  Widget _buildFullscreenVideo() {
    return Stack(
      children: [
        Positioned.fill(
          child: _controller.value.isInitialized
              ? FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller.value.size.width,
                    height: _controller.value.size.height,
                    child: VideoPlayer(_controller),
                  ),
                )
              : const Center(
                  child: CircularProgressIndicator(),
                ),
        ),
        Positioned(
          top: 40,
          right: 20,
          child: GestureDetector(
            onTap: _exitFullScreen,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.fullscreen_exit,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
