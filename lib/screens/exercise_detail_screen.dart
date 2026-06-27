// ignore_for_file: implementation_imports

import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:marquee/marquee.dart';
import 'package:mighty_fitness/models/home_page_workout_list_request.dart';
import 'package:better_player_plus/better_player_plus.dart';
import 'package:better_player_plus/src/video_player/video_player.dart'
    as bp_video;

const Color kBg = Color(0xFF050505);
const Color kCard = Color(0xFF141414);
const Color kAccent = Color(0xFFE10600);
const Color kGlow = Color(0x44E10600);

Color bg(BuildContext c) => Theme.of(c).brightness == Brightness.dark
    ? kBg
    : Theme.of(c).colorScheme.surface;

Color card(BuildContext c) => Theme.of(c).brightness == Brightness.dark
    ? kCard
    : Theme.of(c).colorScheme.surface;

Color textPrimary(BuildContext c) => Theme.of(c).colorScheme.onSurface;

Color textSecondary(BuildContext c) =>
    Theme.of(c).colorScheme.onSurface.withValues(alpha: 0.7);

class ExerciseDetailsScreen extends StatefulWidget {
  final Exercises exercise;
  final int id;
  final String name;
  final String videoPath;
  final String instruction;

  const ExerciseDetailsScreen({
    super.key,
    required this.exercise,
    required this.id,
    required this.name,
    required this.videoPath,
    required this.instruction,
  });

  @override
  State<ExerciseDetailsScreen> createState() => _ExerciseDetailsScreenState();
}

class _ExerciseDetailsScreenState extends State<ExerciseDetailsScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  BetterPlayerController? _bpController;
  dynamic _vpController;
  final ScrollController _instructionScrollCtrl = ScrollController();
  Timer? _autoScrollTimer;
  final GlobalKey _alternateIconKey = GlobalKey();
  bool _isPlayingLocal = false;
  bool _isLoading = true;
  bool _isFullScreen = false;
  bool _muted = false;
  bool _controlsVisible = true;
  double _volume = 1.0;
  int _selectedCard = 0;
  String _currentExerciseName = "";
  String _currentInstruction = "";
  int _playerSession = 0;
  Timer? _hideTimer;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;
  late AnimationController _pulseCtrl;

  late AnimationController _shakeCtrl;

  void _toggleControls() {
    if (!_controlsVisible) {
      _showControlsTemporarily();
    } else {
      _hideTimer?.cancel();
      setState(() => _controlsVisible = false);
      _fadeController.reverse();
    }
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
  }

  List<String> _splitInstruction(String instruction) {
    if (instruction.trim().isEmpty) return [];

    final cleaned = _prepareInstructionText(instruction);

    final extractedSetSteps = _extractSetInstructions(cleaned);
    if (extractedSetSteps.isNotEmpty) {
      return extractedSetSteps;
    }

    final fragments = cleaned
        .split('\n')
        .expand((line) => line.split(RegExp(r'(?=\d+\.\s*)')))
        .map((e) => e.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final List<String> merged = <String>[];
    String current = '';

    for (final fragment in fragments) {
      final hasStepNumber = RegExp(r'^\d+\.\s*').hasMatch(fragment);
      final text = fragment.replaceFirst(RegExp(r'^\d+\.\s*'), '').trim();
      if (text.isEmpty) continue;

      if (current.isEmpty) {
        current = text;
        continue;
      }

      if (hasStepNumber && _isInstructionComplete(current)) {
        merged.add(_normalizeInstructionText(current));
        current = text;
      } else {
        current = '$current $text'.trim();
      }
    }

    if (current.isNotEmpty) {
      merged.add(_normalizeInstructionText(current));
    }

    return merged.expand(_splitRepeatedSetSegments).toList();
  }

  String _prepareInstructionText(String raw) {
    var cleaned = raw
        .replaceAll('\r', '')
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</(p|div|li)>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'\s*(•|·)\s*'), '\n');

    // Some payloads arrive like "18-2. Set..." where the trailing hyphen is
    // only a broken separator before the next numbered instruction.
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'([A-Za-z0-9])\s*[-–—]+\s*(?=\d+\s*[\.\)])'),
      (match) => '${match.group(1)}\n',
    );

    return cleaned.trim();
  }

  List<String> _extractSetInstructions(String text) {
    final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    final matches = RegExp(
      r'(?:\d+\.\s*)?(set\b.*?)(?=(?:\d+\.\s*)?set\b|$)',
      caseSensitive: false,
    ).allMatches(normalized);

    final results = matches
        .map((m) => _normalizeInstructionText((m.group(1) ?? '').trim()))
        .where((e) => e.isNotEmpty)
        .toList();

    return results.length >= 2 ? results : <String>[];
  }

  bool _isInstructionComplete(String text) {
    final normalized = text.toLowerCase();
    return RegExp(
      r'\b(rep|reps|kg|kgs|sec|secs|second|seconds|min|mins|minute|minutes|time|times|x)\b',
    ).hasMatch(normalized);
  }

  String _normalizeInstructionText(String text) {
    var normalized = text.replaceAll('\$', '');
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
    normalized = normalized.replaceAll(RegExp(r'\s*=\s*'), ' = ');
    normalized = normalized.replaceAllMapped(
      RegExp(r'(\d)\s*-\s*(\d)'),
      (match) => '${match.group(1)} - ${match.group(2)}',
    );
    normalized = normalized.replaceAllMapped(
      RegExp(r'(\d)(reps?|sets?|kg|kgs|sec|secs|min|mins)\b',
          caseSensitive: false),
      (match) => '${match.group(1)} ${match.group(2)}',
    );
    normalized = normalized.replaceAllMapped(
      RegExp(r'\b(kg|kgs|sec|secs|min|mins)(\d)', caseSensitive: false),
      (match) => '${match.group(1)} ${match.group(2)}',
    );
    normalized = normalized.replaceAll(RegExp(r'\(\s+'), '(');
    normalized = normalized.replaceAll(RegExp(r'\s+\)'), ')');
    normalized = normalized.replaceAllMapped(
      RegExp(r'\bset\s*=', caseSensitive: false),
      (_) => 'Set =',
    );
    normalized = normalized.replaceFirst(
      RegExp(r'^set\b', caseSensitive: false),
      'Set',
    );
    normalized = normalized.replaceFirst(RegExp(r'\s*[-–—]+\s*$'), '');
    return normalized.trim();
  }

  List<String> _splitRepeatedSetSegments(String text) {
    final normalized = _normalizeInstructionText(text);
    final matches = RegExp(
      r'\bset\b(?=\s*(?:=|\d))',
      caseSensitive: false,
    ).allMatches(normalized).toList();

    if (matches.length <= 1) {
      return <String>[normalized];
    }

    final segments = <String>[];
    for (var i = 0; i < matches.length; i++) {
      final start = matches[i].start;
      final end =
          i + 1 < matches.length ? matches[i + 1].start : normalized.length;
      final part = normalized.substring(start, end).trim();
      if (part.isNotEmpty) {
        segments.add(_normalizeInstructionText(part));
      }
    }
    return segments.isEmpty ? <String>[normalized] : segments;
  }

// ----------------- INSTRUCTION PARSER -----------------

  List<String> finalInstructions() {
    return _parseInstructions(_currentInstruction);
  }

  List<String> _parseInstructions(String raw) {
    return _splitInstruction(raw);
  }

  String _resolvedInstructionText(String title, String instruction) {
    return instruction;
  }

  String _instructionDisplayText(String instruction) {
    return instruction
        .replaceAll('\r', '')
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</(p|div|li)>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), '• ')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAllMapped(
          RegExp(r'\n{3,}'),
          (_) => '\n\n',
        )
        .trim();
  }

  Widget _instructionHelperNote(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : cs.surfaceContainerHighest.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : cs.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: SizedBox(
        height: 22,
        child: Marquee(
          text:
              "You can adjust the weight, but it is mandatory to complete the exact number of reps instructed by CPT.",
          style: GoogleFonts.montserrat(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: textSecondary(context),
          ),
          blankSpace: 56,
          velocity: 24,
          startAfter: const Duration(milliseconds: 500),
          pauseAfterRound: const Duration(milliseconds: 900),
          accelerationDuration: const Duration(milliseconds: 450),
          decelerationDuration: const Duration(milliseconds: 450),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    debugPrint("🎥 MAIN VIDEO URL: ${widget.videoPath}");

    _currentExerciseName = widget.name;
    _currentInstruction =
        _resolvedInstructionText(widget.name, widget.instruction);

    // ================= FADE CONTROLS =================
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _fadeAnim = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    // ================= PULSE (EXISTING) =================
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // ================= SHAKE =================
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    // ================= VIDEO INIT =================
    _prepareAndInitPlayerFor(widget.videoPath);
  }

  // ----------------- YOUTUBE HELPERS -----------------

  Future<void> _switchVideo(
    String url, {
    required String newInstruction,
    required String newName,
  }) async {
    if (url.isEmpty) return;

    HapticFeedback.mediumImpact();
    _shakeCtrl.forward(from: 0);

    setState(() {
      _isLoading = true;
      _currentExerciseName = newName;
      _currentInstruction = _resolvedInstructionText(newName, newInstruction);
    });

    await _prepareAndInitPlayerFor(url);
  }

  Future<void> _handleBack() async {
    if (_isFullScreen) {
      await _exitFullScreen();
      return;
    }

    Navigator.of(context).pop();
  }

  Future<bool> _onWillPop() async {
    if (_isFullScreen) {
      await _exitFullScreen();
      return false;
    }
    return true;
  }

  Future<void> _prepareAndInitPlayerFor(String videoUrl) async {
    // ❌ Empty URL safety
    if (videoUrl.trim().isEmpty) {
      final controller = _bpController;
      if (controller != null) {
        controller.pause();
      }
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isPlayingLocal = false;
      });
      return;
    }

    final session = ++_playerSession;

    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final isHls = videoUrl.toLowerCase().contains('.m3u8');
      await _disposeCurrentController();
      if (!mounted || session != _playerSession) {
        return;
      }

      final controller = _createPlayerController();

      final dataSource = BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        videoUrl,
        videoFormat: isHls ? BetterPlayerVideoFormat.hls : null,
        useAsmsTracks: false,
        useAsmsSubtitles: false,
        useAsmsAudioTracks: false,
        cacheConfiguration: const BetterPlayerCacheConfiguration(
          useCache: false,
          maxCacheSize: 60 * 1024 * 1024,
          maxCacheFileSize: 20 * 1024 * 1024,
        ),
        bufferingConfiguration: const BetterPlayerBufferingConfiguration(
          minBufferMs: 4000,
          maxBufferMs: 15000,
          bufferForPlaybackMs: 1000,
          bufferForPlaybackAfterRebufferMs: 1500,
        ),
      );

      await controller.setupDataSource(dataSource);
      if (!mounted || session != _playerSession) {
        return;
      }

      final vp = controller.videoPlayerController;
      if (vp == null || !vp.value.initialized) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _isPlayingLocal = false;
        });
        return;
      }

      await controller.setVolume(_volume);
      await controller.play();

      if (!mounted || session != _playerSession) {
        return;
      }

      setState(() {
        _bpController = controller;
        _vpController = vp;
        _isLoading = false;
        _isPlayingLocal = true;
      });

      // 🎬 Show controls fade
      _fadeController.forward();
    } catch (e) {
      debugPrint("❌ Video init error: $e");

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  BetterPlayerController _createPlayerController() {
    final controller = BetterPlayerController(
      const BetterPlayerConfiguration(
        autoPlay: false,
        fit: BoxFit.contain,
        looping: true,
        autoDispose: false,
        handleLifecycle: false,
        controlsConfiguration: BetterPlayerControlsConfiguration(
          showControls: false,
        ),
      ),
    );

    controller.addEventsListener(_onPlayerEvent);
    _bpController = controller;
    return controller;
  }

  void _onPlayerEvent(BetterPlayerEvent event) {
    final controller = _bpController;
    if (!mounted || controller == null) return;

    final type = event.betterPlayerEventType;
    if (type == BetterPlayerEventType.play ||
        type == BetterPlayerEventType.pause ||
        type == BetterPlayerEventType.finished) {
      final isPlayingNow = controller.isPlaying() ?? false;
      if (_isPlayingLocal != isPlayingNow) {
        setState(() {
          _isPlayingLocal = isPlayingNow;
        });
      }
    }
  }

  Future<void> _disposeCurrentController() async {
    final c = _bpController;
    _bpController = null;
    _vpController = null;

    try {
      if (c != null) {
        await c.pause();
        c.removeEventsListener(_onPlayerEvent);
        c.dispose(forceDispose: true);
      }
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _bpController;
    if (controller == null) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      controller.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hideTimer?.cancel();
    _autoScrollTimer?.cancel();

    _instructionScrollCtrl.dispose();
    _fadeController.dispose();
    _pulseCtrl.dispose();
    _shakeCtrl.dispose();

    _disposeCurrentController();
    super.dispose();
  }

//  Future<void> _disposeCurrentController() async {
//   try {
//     final c = _ytController;
//     if (c != null) {
//       c.pause();      // stop playback
//       c.dispose();    // release WebView + media
//       _ytController = null;
//     }
//   } catch (e) {
//     debugPrint("YT dispose error: $e");
//   }
// }
  // ----------------- COMMON PLAYER ACTIONS -----------------

  void _showControlsTemporarily() {
    _hideTimer?.cancel();
    setState(() => _controlsVisible = true);
    _fadeController.forward();

    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      setState(() => _controlsVisible = false);
      _fadeController.reverse();
    });
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      final h = d.inHours.toString().padLeft(2, '0');
      final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
      final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
      return "$h:$m:$s";
    } else {
      final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
      final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
      return "$m:$s";
    }
  }

  void _togglePlayPause() {
    final bp = _bpController;
    final vp = _vpController;
    if (bp == null || vp == null || !vp.value.initialized) return;

    final willPlay = !vp.value.isPlaying;

    if (vp.value.isPlaying) {
      _stopAutoScroll(); // 🔥 ADD THIS
      bp.pause();
    } else {
      bp.play();
    }

    setState(() {
      _isPlayingLocal = willPlay;
    });

    _showControlsTemporarily();
  }

  void _seekRelative(Duration offset) {
    final bp = _bpController;
    final vp = _vpController;
    if (bp == null || vp == null || !vp.value.initialized) return;

    final pos = vp.value.position;
    final dur = vp.value.duration;
    if (dur == null || dur == Duration.zero) return;

    var newPos = pos + offset;
    if (newPos < Duration.zero) newPos = Duration.zero;
    if (newPos > dur) newPos = dur;

    bp.seekTo(newPos);
    _showControlsTemporarily();
  }

  void _setVolume(double v) {
    final bp = _bpController;
    final vp = _vpController;
    if (bp == null || vp == null || !vp.value.initialized) return;

    _volume = v.clamp(0.0, 1.0);
    _muted = _volume == 0;
    bp.setVolume(_volume);

    setState(() {});
    _showControlsTemporarily();
  }

  Future<void> _openFullScreenRoute() async {
    final vp = _vpController;
    if (_isFullScreen || vp == null || !vp.value.initialized) return;

    setState(() {
      _isFullScreen = true;
      _controlsVisible = true;
    });

    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
    );

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    if (!mounted) return;

    await Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 180),
        reverseTransitionDuration: const Duration(milliseconds: 180),
        opaque: false,
        transitionsBuilder: (ctx, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          );
        },
        pageBuilder: (ctx, animation, secondaryAnimation) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: SafeArea(
              top: false,
              bottom: false,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: _buildVideoStack(
                      overlayContext: ctx,
                      renderVideo: true,
                      onSurfaceTap: _toggleControls,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    await _exitFullScreen();
  }

  Future<void> _exitFullScreen() async {
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    if (!mounted) return;
    setState(() => _isFullScreen = false);
  }

  Future<void> _dismissVideoView(BuildContext context) async {
    if (_isFullScreen) {
      await Navigator.of(context).maybePop();
      return;
    }
    await _handleBack();
  }

  Widget _buildVideoStack({
    required BuildContext overlayContext,
    required bool renderVideo,
    required VoidCallback onSurfaceTap,
  }) {
    final bp_video.VideoPlayerController? videoController =
        _vpController is bp_video.VideoPlayerController ? _vpController : null;
    final bool hideBackdropVideoOnIosFullscreen =
        _isFullScreen && defaultTargetPlatform == TargetPlatform.iOS;
    final bool useDarkVideoChrome =
        _isFullScreen || Theme.of(overlayContext).brightness == Brightness.dark;
    final Color videoBaseColor = useDarkVideoChrome
        ? Colors.black
        : Theme.of(overlayContext).colorScheme.surface;

    return Stack(
      children: [
        /// VIDEO (Only when ready)
        if (renderVideo &&
            videoController != null &&
            videoController.value.initialized &&
            videoController.value.size != null)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_isFullScreen ? 0 : 8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: videoBaseColor,
                    child: hideBackdropVideoOnIosFullscreen
                        ? const SizedBox.expand()
                        : ImageFiltered(
                            imageFilter:
                                ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Opacity(
                              opacity: 0.55,
                              child: FittedBox(
                                fit: BoxFit.cover,
                                child: SizedBox(
                                  width: videoController.value.size!.width,
                                  height: videoController.value.size!.height,
                                  child: bp_video.VideoPlayer(videoController),
                                ),
                              ),
                            ),
                          ),
                  ),
                  Center(
                    child: AspectRatio(
                      aspectRatio: videoController.value.aspectRatio == 0
                          ? 9 / 16
                          : videoController.value.aspectRatio,
                      child: bp_video.VideoPlayer(videoController),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.06),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        /// LOADER (Center me)
        if (_isLoading ||
            _vpController == null ||
            !_vpController!.value.initialized)
          const Center(
            child: SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: kAccent,
              ),
            ),
          ),

        /// TAP
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onSurfaceTap,
            child: const SizedBox.expand(),
          ),
        ),

        /// PLAY BUTTON
        if (_vpController != null &&
            _vpController!.value.initialized &&
            !_isPlayingLocal)
          Center(
            child: GestureDetector(
              onTap: _togglePlayPause,
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  size: 28,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        if (_controlsVisible && renderVideo) _controlsOverlay(overlayContext),
        if (renderVideo && _isFullScreen)
          Positioned(
            top: _isFullScreen ? 18 : 12,
            left: 12,
            child: SafeArea(
              bottom: false,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _dismissVideoView(overlayContext),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.42),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _alternateSetSection(
    BuildContext context,
    AlternateExercise? alternateExercise,
  ) {
    // 🔥 CASE 1: Alternate NOT available
    if (alternateExercise == null) {
      // 👉 MAIN instruction ko hi use karo
      final mainInstruction =
          _resolvedInstructionText(widget.name, widget.instruction);

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// HEADER
            Text(
              "Exercise Instruction",
              style: GoogleFonts.montserrat(
                color: textPrimary(context),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            _instructionHelperNote(context),

            const SizedBox(height: 14),

            /// 🔥 SINGLE CARD (MAIN EXERCISE)
            _altCard(
              widget.name,
              mainInstruction, // 👈 YAHI MAIN FIX HAI
              true,
              index: 0,
              width: double.infinity,
              margin: EdgeInsets.zero,
              titleMaxLines: 3,
              shrinkToFit: true,
              minHeight: 280,
              onTap: () {
                if (_selectedCard == 0) return;

                setState(() => _selectedCard = 0);

                _switchVideo(
                  widget.videoPath,
                  newInstruction: mainInstruction,
                  newName: widget.name,
                );
              },
            ),
          ],
        ),
      );
    }

    // 🔥 CASE 2: Alternate available (EXISTING LOGIC)
    final alternateInstruction = alternateExercise.cleanInstruction;
    final cardHeight =
        (MediaQuery.of(context).size.height * 0.29).clamp(230.0, 300.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Alternate Set",
            style: GoogleFonts.montserrat(
              color: textPrimary(context),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Choose your next move",
            style: GoogleFonts.montserrat(
              color: textSecondary(context),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 6),
          _instructionHelperNote(context),
          const SizedBox(height: 12),
          SizedBox(
            height: cardHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 12,
                  child: _altCard(
                    widget.name,
                    _resolvedInstructionText(widget.name, widget.instruction),
                    _selectedCard == 0,
                    index: 0,
                    width: double.infinity,
                    margin: EdgeInsets.zero,
                    onTap: () {
                      final altVideoUrl = alternateExercise.resolvedVideoUrl;

                      debugPrint("🔁 ALTERNATE VIDEO URL: $altVideoUrl");
                      if (_selectedCard == 0) return;

                      setState(() => _selectedCard = 0);

                      _switchVideo(
                        widget.videoPath,
                        newInstruction: widget.instruction,
                        newName: widget.name,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 6),
                _alternateDividerIcon(
                  iconKey: _alternateIconKey,
                ),
                const SizedBox(width: 6),
                if (alternateInstruction.isNotEmpty)
                  Expanded(
                    flex: 12,
                    child: _altCard(
                      alternateExercise.title ?? "Alternate Exercise",
                      alternateInstruction,
                      _selectedCard == 1,
                      index: 1,
                      width: double.infinity,
                      margin: EdgeInsets.zero,
                      onTap: () {
                        if (_selectedCard == 1) return;

                        final altVideoUrl = alternateExercise.resolvedVideoUrl;

                        if (altVideoUrl.isEmpty) return;

                        setState(() => _selectedCard = 1);

                        _switchVideo(
                          altVideoUrl,
                          newInstruction: alternateInstruction,
                          newName: alternateExercise.title ?? "",
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _altCard(
    String title,
    String instruction,
    bool active, {
    required int index,
    double width = 220,
    EdgeInsetsGeometry margin = const EdgeInsets.only(right: 12),
    int titleMaxLines = 4,
    bool shrinkToFit = false,
    double? minHeight,
    required VoidCallback onTap,
  }) {
    final displayInstruction = _instructionDisplayText(instruction);
    final EdgeInsetsGeometry contentPadding = shrinkToFit
        ? const EdgeInsets.fromLTRB(14, 16, 14, 14)
        : const EdgeInsets.fromLTRB(16, 18, 16, 16);
    final double cardRadius = shrinkToFit ? 26 : 30;

    return AnimatedBuilder(
      animation: _shakeCtrl,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, active ? 0 : 4),
          child: child,
        );
      },
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          width: width,
          margin: margin,
          constraints:
              minHeight == null ? null : BoxConstraints(minHeight: minHeight),
          padding: contentPadding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(cardRadius),
            gradient: active
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFE10600),
                      Color(0xFFFF2A20),
                    ],
                  )
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF121212),
                      Color(0xFF050505),
                    ],
                  ),
            border: active
                ? Border.all(
                    color: Colors.white.withValues(alpha: 0.28),
                    width: 1.3,
                  )
                : Border.all(color: Colors.white.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: active ? kGlow : Colors.black.withValues(alpha: 0.24),
                blurRadius: active ? 30 : 18,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: shrinkToFit ? MainAxisSize.min : MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.fitness_center,
                size: 22,
                color: Colors.white,
              ),
              SizedBox(height: shrinkToFit ? 10 : 14),
              Text(
                title.toUpperCase(),
                maxLines: titleMaxLines,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: shrinkToFit ? 10.8 : 11.2,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  letterSpacing: 0.35,
                ),
              ),
              SizedBox(height: shrinkToFit ? 10 : 12),
              Text(
                "Instruction",
                style: GoogleFonts.montserrat(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontSize: shrinkToFit ? 10.2 : 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: shrinkToFit ? 6 : 8),
              if (shrinkToFit)
                _instructionBody(displayInstruction)
              else
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: _instructionBody(displayInstruction),
                    ),
                  ),
                ),
              if (shrinkToFit) const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }

  Widget _instructionBody(String instruction) {
    if (instruction.isEmpty) {
      return Text(
        "No instruction",
        style: GoogleFonts.montserrat(
          color: Colors.white60,
          fontSize: 10,
        ),
      );
    }

    return Text(
      instruction,
      textAlign: TextAlign.left,
      softWrap: true,
      style: GoogleFonts.montserrat(
        color: Colors.white.withValues(alpha: 0.95),
        fontSize: 10.4,
        fontWeight: FontWeight.w600,
        height: 1.42,
      ),
    );
  }

  Widget _miniBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black45,
        ),
        child: Icon(
          icon,
          size: 16,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _controlsOverlay(BuildContext ctx) {
    final c = _vpController;
    if (c == null) return const SizedBox.shrink();

    final mediaQuery = MediaQuery.of(ctx);
    final availableWidth = mediaQuery.size.width;
    final safeBottom = mediaQuery.padding.bottom;
    final sliderFixedWidth = (availableWidth * 0.3).clamp(80.0, 160.0);

    return ValueListenableBuilder(
      valueListenable: c,
      builder: (context, value, _) {
        final dynamic v = value;
        if (v == null) return const SizedBox.shrink();

        final dur = v.duration;
        if (!v.initialized || dur == null || dur == Duration.zero) {
          return const SizedBox.shrink();
        }

        final pos = v.position;
        final sliderValue =
            (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0);

        return Positioned.fill(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _toggleControls,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 30,
                    right: 30,
                    bottom: (_isFullScreen ? safeBottom + 8 : 8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: RepaintBoundary(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _controlContent(
                          ctx,
                          c,
                          pos,
                          dur,
                          sliderValue,
                          sliderFixedWidth,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _controlContent(
    BuildContext ctx,
    dynamic c,
    Duration pos,
    Duration dur,
    double sliderValue,
    double sliderFixedWidth,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),

          /// 🏷 TITLE
          SizedBox(
            width: double.infinity,
            child: Text(
              _currentExerciseName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),

          /// ⏱ SEEK BAR
          Row(
            children: [
              Text(
                _formatDuration(pos),
                style: GoogleFonts.montserrat(
                  color: Colors.white70,
                  fontSize: 10,
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(ctx).copyWith(
                    trackHeight: 3,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 5),
                    thumbColor: Colors.white,
                    activeTrackColor: kAccent,
                    inactiveTrackColor: Colors.white24,
                  ),
                  child: Slider(
                    min: 0,
                    max: 1,
                    value: sliderValue,
                    onChanged: (v) {
                      c.seekTo(
                        Duration(
                          milliseconds: (v * dur.inMilliseconds).toInt(),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Text(
                _formatDuration(dur),
                style: GoogleFonts.montserrat(
                  color: Colors.white70,
                  fontSize: 10,
                ),
              ),
            ],
          ),

          /// 🎛 ACTIONS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              /// ⏪ ⏯ ⏩
              Row(
                children: [
                  _miniBtn(
                    Icons.replay_10,
                    () => _seekRelative(
                      const Duration(seconds: -15),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: _togglePlayPause,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black45,
                      ),
                      child: Icon(
                        _isPlayingLocal ? Icons.pause : Icons.play_arrow,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _miniBtn(
                    Icons.forward_10,
                    () => _seekRelative(
                      const Duration(seconds: 15),
                    ),
                  ),
                ],
              ),

              /// 🔊 🔳
              Row(
                children: [
                  IconButton(
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      final bp = _bpController;
                      if (bp == null) return;
                      setState(() {
                        _muted = !_muted;
                        _volume = _muted ? 0 : 1;
                      });
                      bp.setVolume(_volume);
                    },
                    icon: Icon(
                      _muted ? Icons.volume_off : Icons.volume_up,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(
                    width: sliderFixedWidth,
                    child: Slider(
                      value: _volume,
                      min: 0,
                      max: 1,
                      onChanged: _setVolume,
                      activeColor: kAccent,
                      inactiveColor: Colors.white24,
                    ),
                  ),
                  IconButton(
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () async {
                      if (_isFullScreen) {
                        await Navigator.of(ctx).maybePop();
                        return;
                      }
                      await _openFullScreenRoute();
                    },
                    icon: Icon(
                      _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ----------------- BUILD -----------------

  @override
  Widget build(BuildContext context) {
    // final screenW = MediaQuery.of(context).size.width;
    // final screenH = MediaQuery.of(context).size.height;

    // final frameHeight = _isFullScreen
    //     ? screenH
    //     : (_vpController != null && _vpController!.value.initialized)
    //         ? screenW / _vpController!.value.aspectRatio
    //         : screenW * 9 / 16;

    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: bg(context),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: bg(context),
          surfaceTintColor: bg(context),
          automaticallyImplyLeading: false,
          leading: GestureDetector(
            onTap: _handleBack,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(
                Icons.arrow_back_ios_new,
                size: 20,
                color: textPrimary(context),
              ),
            ),
          ),
          title: Text(
            _currentExerciseName,
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.bold,
              color: textPrimary(context),
            ),
          ),
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final videoHeight =
                  (constraints.maxHeight * 0.58).clamp(340.0, 560.0);

              return Column(
                children: [
                  SizedBox(
                    height: videoHeight,
                    width: double.infinity,
                    child: _buildVideoStack(
                      overlayContext: context,
                      renderVideo: true,
                      onSurfaceTap: _toggleControls,
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.zero,
                      child: _alternateSetSection(
                        context,
                        widget.exercise.alternateExercise,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

Widget _alternateDividerIcon({
  required Key iconKey,
}) {
  return GestureDetector(
    key: iconKey, // 👈 VERY IMPORTANT
    child: Container(
      width: 42,
      alignment: Alignment.center,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: kAccent.withValues(alpha: 0.15),
          border: Border.all(color: kAccent),
        ),
        child: const Icon(
          Icons.swap_horiz,
          size: 16,
          color: kAccent,
        ),
      ),
    ),
  );
}
