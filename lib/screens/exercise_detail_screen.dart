import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:marquee/marquee.dart';
import 'package:mighty_fitness/models/home_page_workout_list_request.dart';
import 'package:better_player_plus/better_player_plus.dart';

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
    Theme.of(c).colorScheme.onSurface.withOpacity(0.7);

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
  bool _hasError = false;
  bool _isFullScreen = false;
  bool _muted = false;
  bool _controlsVisible = true;
  bool _showRestHud = false;
  double _volume = 1.0;
  int _selectedCard = 0;
  String _currentExerciseName = "";
  String _currentInstruction = "";
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

    // new line OR numbering OR comma handle
    return instruction
        .replaceAll('\r', '')
        .split(RegExp(r'\n|(?=\d+\.)'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

// ----------------- INSTRUCTION PARSER -----------------

  List<String> finalInstructions() {
    return _parseInstructions(_currentInstruction);
  }

  List<String> _parseInstructions(String raw) {
    if (raw.trim().isEmpty) return [];

    final cleaned = raw
        // remove all html tags like <div>
        .replaceAll(RegExp(r'<[^>]*>'), '\n')
        // remove html spaces
        .replaceAll('&nbsp;', ' ')
        // multiple new lines → single
        .replaceAll(RegExp(r'\n+'), '\n')
        .trim();

    return cleaned
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    debugPrint("🎥 MAIN VIDEO URL: ${widget.videoPath}");

    _currentExerciseName = widget.name;
    _currentInstruction = widget.instruction;

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
      _currentInstruction = newInstruction;
    });

    await _prepareAndInitPlayerFor(url);
  }

  Future<void> _handleBack() async {
    if (_isFullScreen) {
      Navigator.of(context).maybePop();
      return;
    }

    Navigator.of(context).pop();
  }

  Future<bool> _onWillPop() async {
    if (_isFullScreen) {
      Navigator.of(context).maybePop();
      return false;
    }
    return true;
  }

  Future<void> _prepareAndInitPlayerFor(String videoUrl) async {
    // 🔁 Purana controller cleanly dispose karo
    await _disposeCurrentController();

    // ❌ Empty URL safety
    if (videoUrl.trim().isEmpty) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final isHls = videoUrl.toLowerCase().contains('.m3u8');

      // 🎥 Create controller
      final controller = BetterPlayerController(
        const BetterPlayerConfiguration(
          autoPlay: false,
          fit: BoxFit.contain,
          looping: true,
          autoDispose: false,
          handleLifecycle: true,
          controlsConfiguration: BetterPlayerControlsConfiguration(
            showControls: false,
          ),
        ),
      );

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

      // ⏳ Initialize
      await controller.setupDataSource(dataSource);
      final vp = controller.videoPlayerController;
      // ❗ Safety check (very important)
      if (vp == null || !vp.value.initialized) {
        controller.dispose();
        if (!mounted) return;
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
        return;
      }

      // ▶️ Configure playback
      await controller.setVolume(_volume);
      await controller.play();

      if (!mounted) {
        controller.dispose();
        return;
      }

      // ✅ Attach controller to UI
      setState(() {
        _bpController = controller;
        _vpController = vp;
        _isLoading = false;
        _isPlayingLocal = true;
      });

      controller.addEventsListener((event) {
        if (!mounted || _bpController != controller) return;

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
      });

      // 🎬 Show controls fade
      _fadeController.forward();
    } catch (e) {
      debugPrint("❌ Video init error: $e");

      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _disposeCurrentController() async {
    try {
      final c = _bpController;
      if (c != null) {
        await c.pause();
        c.dispose();
      }
      _bpController = null;
      _vpController = null;
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
      _showRestHud = willPlay;
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
    _showRestHud = false;
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
            backgroundColor: Colors.transparent,
            body: SafeArea(
              top: false,
              bottom: false,
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                          // gradient: LinearGradient(
                          //   begin: Alignment.topCenter,
                          //   end: Alignment.bottomCenter,
                          //   colors: [
                          //     kBg,
                          //     kBg.withOpacity(0.96),
                          //     const Color(0xFF120404),
                          //   ],
                          // ),
                          ),
                    ),
                  ),
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 18),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            // border: Border.all(
                            //   color: Colors.white.withOpacity(0.12),
                            //   width: 1.1,
                            // ),
                          ),
                          child: _buildVideoStack(
                            overlayContext: ctx,
                            renderVideo: true,
                            onSurfaceTap: _toggleControls,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 12,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => Navigator.of(ctx).maybePop(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withOpacity(0.42),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.18),
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

  Widget _buildVideoStack({
    required BuildContext overlayContext,
    required bool renderVideo,
    required VoidCallback onSurfaceTap,
  }) {
    return Stack(
      children: [
        /// VIDEO (Only when ready)
        if (renderVideo &&
            _vpController != null &&
            _vpController!.value.initialized)
          FractionallySizedBox(
            widthFactor: 2.7,
            heightFactor: 2.7,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _bpController == null
                  ? const SizedBox.shrink()
                  : RepaintBoundary(
                      child: BetterPlayer(
                        controller: _bpController!,
                      ),
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
      final mainInstruction = widget.instruction;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 75, horizontal: 16),
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

            SizedBox(
              height: 26,
              child: Marquee(
                text:
                    "🏋️ You can adjust the weight, but it is mandatory that you perform the exact number of reps (repetitions) compulsory as instructed by CPT. 🔁",
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: textSecondary(context),
                ),
                scrollAxis: Axis.horizontal,
                velocity: 35.0,
                blankSpace: 40,
                pauseAfterRound: const Duration(seconds: 1),
                startPadding: 10,
                accelerationDuration: const Duration(milliseconds: 600),
                decelerationDuration: const Duration(milliseconds: 600),
              ),
            ),

            const SizedBox(height: 14),

            /// 🔥 SINGLE CARD (MAIN EXERCISE)
            SizedBox(
              height: 185,
              child: _altCard(
                widget.name,
                mainInstruction, // 👈 YAHI MAIN FIX HAI
                true,
                index: 0,
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
            ),
          ],
        ),
      );
    }

    // 🔥 CASE 2: Alternate available (EXISTING LOGIC)
    final alternateInstruction = alternateExercise.cleanInstruction;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 65, horizontal: 10),
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
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 26,
            child: Marquee(
              text:
                  "🏋️ You can adjust the weight, but it is mandatory that you perform the exact number of reps (repetitions) compulsory as instructed by CPT. 🔁",
              style: GoogleFonts.montserrat(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textSecondary(context),
              ),
              scrollAxis: Axis.horizontal,
              velocity: 35.0,
              blankSpace: 40,
              pauseAfterRound: const Duration(seconds: 1),
              startPadding: 10,
              accelerationDuration: const Duration(milliseconds: 600),
              decelerationDuration: const Duration(milliseconds: 600),
            ),
          ),
          SizedBox(
            height: 185,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                /// MAIN
                _altCard(
                  widget.name,
                  widget.instruction,
                  _selectedCard == 0,
                  index: 0,
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

                _alternateDividerIcon(
                  iconKey: _alternateIconKey,
                ),

                /// ALTERNATE
                if (alternateInstruction.isNotEmpty)
                  _altCard(
                    alternateExercise.title ?? "Alternate Exercise",
                    alternateInstruction,
                    _selectedCard == 1,
                    index: 1,
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
    required VoidCallback onTap,
  }) {
    // 🔹 Clean instruction text
    final cleanInstruction = instruction
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .trim();

    // ✅ YAHI PE steps DEFINE KARO (IMPORTANT)
    final List<String> steps = _splitInstruction(cleanInstruction);

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
          width: 161,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),

            /// 🔥 GRADIENT BACKGROUND
            gradient: active
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFE10600),
                      Color(0xFFE10600),
                    ],
                  )
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1A1A1A),
                      Color(0xFF121212),
                      Color(0xFF0B0B0B),
                    ],
                  ),

            /// ✨ BORDER + SHADOW
            border: active
                ? Border.all(color: const Color(0xFFE10600), width: 1.2)
                : Border.all(color: Colors.white10),

            boxShadow: [
              if (active)
                const BoxShadow(
                  color: kGlow,
                  blurRadius: 28,
                  offset: Offset(0, 12),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// ICON
              const Icon(
                Icons.fitness_center,
                size: 26,
                color: Colors.white,
              ),

              const SizedBox(height: 12),

              /// TITLE
              Text(
                title.toUpperCase(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),

              const SizedBox(height: 10),

              /// LABEL
              Text(
                "Instruction",
                style: GoogleFonts.montserrat(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              /// ✅ SCROLLABLE INSTRUCTION AREA (ALL LINES)
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: steps.isEmpty
                          ? [
                              Text(
                                "No instruction",
                                style: GoogleFonts.montserrat(
                                  color: Colors.white38,
                                  fontSize: 10,
                                ),
                              ),
                            ]
                          : steps.asMap().entries.map((entry) {
                              final index = entry.key + 1;
                              final text = entry.value.replaceFirst(
                                RegExp(r'^\d+\.'),
                                '',
                              );

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "$index. ",
                                      style: GoogleFonts.montserrat(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        text.trim(),
                                        style: GoogleFonts.montserrat(
                                          color: Colors.white.withOpacity(0.95),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
                        Navigator.of(ctx).maybePop();
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
        appBar: _isFullScreen
            ? null
            : AppBar(
                elevation: 0,
                backgroundColor: Colors.transparent,
                // 👇 REMOVE default iconTheme back button
                automaticallyImplyLeading: false,

                // 🍎 iOS STYLE BACK
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
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: _isFullScreen ? 1 : 2,
            itemBuilder: (context, index) {
              /// ===============================
              /// 0️⃣ VIDEO PLAYER SECTION
              /// ===============================

              if (index == 0) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final screenW = MediaQuery.of(context).size.width;
                    final screenH = MediaQuery.of(context).size.height;

                    final halfHeight = screenW * (4.6 / 4); // 4:5
                    final fullHeight = screenH; // 9:16

                    return SizedBox(
                      width: double.infinity,
                      height: _isFullScreen ? fullHeight : halfHeight,
                      child: _buildVideoStack(
                        overlayContext: context,
                        renderVideo: !_isFullScreen,
                        onSurfaceTap: () async {
                          if (_isFullScreen) {
                            _toggleControls();
                            return;
                          }

                          if (_controlsVisible) {
                            await _openFullScreenRoute();
                            return;
                          }

                          _showControlsTemporarily();
                        },
                      ),
                    );
                  },
                );
              }

              /// ===============================
              /// 1️⃣ ALTERNATE SET SECTION
              /// ===============================
              if (index == 1) {
                return _alternateSetSection(
                  context,
                  widget.exercise.alternateExercise,
                );
              }
              return const SizedBox.shrink();
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
          color: kAccent.withOpacity(0.15),
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
