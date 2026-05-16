import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class WorkoutScrollableBody extends StatelessWidget {
  final bool isFullScreen;
  final double videoHeight;

  final YoutubePlayerController? controller;
  final bool isLoading;
  final bool hasError;
  final bool showRestHud;
  final bool controlsVisible;

  final VoidCallback onTogglePlayPause;
  final VoidCallback onShowControls;
  final VoidCallback onEnterFullScreen;
  final VoidCallback onExitFullScreen;

  final Widget Function(BuildContext) controlsOverlay;
  final Widget errorWidget;

  // Alternate set
  final dynamic alternateExercise;
  final String mainName;
  final String mainInstruction;
  final String mainVideoPath;
  final String alternateInstruction;
  final int selectedCard;

  final void Function(int index) onSelectCard;
  final Widget Function() alternateDividerIcon;
 final Widget Function({
  required String title,
  required String instruction,
  required bool active,
  required int index,
  required VoidCallback onTap,
}) altCard;


  final EdgeInsets safePadding;

  const WorkoutScrollableBody({
    super.key,
    required this.isFullScreen,
    required this.videoHeight,
    required this.controller,
    required this.isLoading,
    required this.hasError,
    required this.showRestHud,
    required this.controlsVisible,
    required this.onTogglePlayPause,
    required this.onShowControls,
    required this.onEnterFullScreen,
    required this.onExitFullScreen,
    required this.controlsOverlay,
    required this.errorWidget,
    required this.alternateExercise,
    required this.mainName,
    required this.mainInstruction,
    required this.mainVideoPath,
    required this.alternateInstruction,
    required this.selectedCard,
    required this.onSelectCard,
    required this.alternateDividerIcon,
    required this.altCard,
    required this.safePadding,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: isFullScreen ? 1 : 2,
        itemBuilder: (context, index) {
          // ================= VIDEO =================
          if (index == 0) {
            return SizedBox(
              height: videoHeight,
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          if (isLoading)
                            const Center(
                              child: CircularProgressIndicator(
                                  color: Colors.white),
                            )
                          else if (hasError)
                            errorWidget
                          else if (controller != null)
                            Positioned.fill(
                              child: AspectRatio(
                                aspectRatio: 9 / 16,
                                child: YoutubePlayer(
                                  controller: controller!,
                                  showVideoProgressIndicator: false,
                                ),
                              ),
                            ),

                          // background tap only when playing
                          if (controller != null &&
                              controller!.value.isPlaying)
                            Positioned.fill(
                              child: GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onTap: onShowControls,
                                child: const SizedBox.expand(),
                              ),
                            ),

                          // play button
                          if (controller != null &&
                              !controller!.value.isPlaying &&
                              !isLoading &&
                              !hasError)
                            Center(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: onTogglePlayPause,
                                child: Container(
                                  padding: const EdgeInsets.all(22),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black,
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black54,
                                        blurRadius: 25,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow_rounded,
                                    size: 28,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),

                          if (showRestHud && !isLoading && !hasError)
                            Positioned(
                              bottom: 120,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.65),
                                    borderRadius:
                                        BorderRadius.circular(16),
                                  ),
                                  child: const Text(
                                    "REST 30s",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                          if (controlsVisible &&
                              !isLoading &&
                              !hasError &&
                              controller != null)
                            controlsOverlay(context),
                        ],
                      ),
                    ),
                  ),

                  // fullscreen button
                  Positioned(
                    right: 18,
                    bottom: 18 +
                        (safePadding.bottom > 0
                            ? safePadding.bottom
                            : 0),
                    child: GestureDetector(
                      onTap: isFullScreen
                          ? onExitFullScreen
                          : onEnterFullScreen,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isFullScreen
                              ? Icons.fullscreen_exit
                              : Icons.fullscreen,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          // ================= ALTERNATE SET =================
          if (alternateExercise == null) {
            return const SizedBox.shrink();
          }

          return Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Alternate Set",
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 14),
               SizedBox(
  height: 185,
  child: ListView(
    scrollDirection: Axis.horizontal,
    children: [
      altCard(
        title: mainName,
        instruction: mainInstruction,
        active: selectedCard == 0,
        index: 0,
        onTap: () => onSelectCard(0),
      ),

      alternateDividerIcon(),

      if (alternateInstruction.trim().isNotEmpty)
        altCard(
          title: alternateExercise.title ?? "Alternate Exercise",
          instruction: alternateInstruction,
          active: selectedCard == 1,
          index: 1,
          onTap: () => onSelectCard(1),
        ),
    ],
  ),
),

              ],
            ),
          );
        },
      ),
    );
  }
}


