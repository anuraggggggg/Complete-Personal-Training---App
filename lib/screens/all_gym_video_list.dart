import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:mighty_fitness/controllers/get_all_exercise_controller/get_all_exercisse_controller.dart';
import 'package:mighty_fitness/models/get_all_exercise_model.dart';
import 'package:mighty_fitness/screens/home_page_wigets/all_exercises_language_bottom_sheet.dart';
import 'package:mighty_fitness/utils/app_colors.dart';
import 'gym_video_player_screen.dart';

class AllGymVideoList extends StatefulWidget {
  const AllGymVideoList({super.key});
  @override
  State<AllGymVideoList> createState() => _AllGymVideoListState();
}

class _AllGymVideoListState extends State<AllGymVideoList> {
  final EquipmentExerciseController controller =
      Get.put(EquipmentExerciseController());

  final TextEditingController searchCtrl = TextEditingController();

  /// 🔥 REACTIVE FILTERED LIST
  final RxList<ExerciseItem> filteredList = <ExerciseItem>[].obs;

  late Worker _exerciseWorker;
  late Worker _categoryWorker;
  // bool _defaultCategoryApplied = false;

  @override
  void initState() {
    super.initState();

    _categoryWorker = ever<List>(controller.categoryList, (list) {
      if (list.isEmpty) return;

      // ✅ Apply default ONLY if nothing is selected
      if (controller.selectedCategoryId.value != 0) return;

      final defaultCategory = list.firstWhereOrNull(
            (c) => (c.title ?? "").toLowerCase() == "dumbbells",
          ) ??
          list.first;

      controller.selectedCategoryId.value = defaultCategory.id!;
      controller.fetchExercisesByCategory(defaultCategory.id!);
    });

    _exerciseWorker = ever(controller.exerciseList, (_) {
      _applyFilter();
    });

    searchCtrl.addListener(_applyFilter);
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    _exerciseWorker.dispose();
    _categoryWorker.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // 🔍 SEARCH FILTER (SAFE)
  // ------------------------------------------------------------
  void _applyFilter() {
    final q = searchCtrl.text.trim().toLowerCase();

    if (q.isEmpty) {
      filteredList.assignAll(controller.exerciseList);
    } else {
      filteredList.assignAll(
        controller.exerciseList.where(
          (e) => (e.title ?? "").toLowerCase().contains(q),
        ),
      );
    }
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "All Gym Videos",
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 70),
        child: _languageFab(),
      ),
      body: Stack(
        children: [
          _mainContent(cs),

          /// 🔵 TOP NON-BLOCKING LOADER
          Obx(() => controller.isSyncingExercises.value
              ? const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(minHeight: 2),
                )
              : const SizedBox()),
        ],
      ),
    );
  }

  Widget _mainContent(ColorScheme cs) {
    return Column(
      children: [
        const SizedBox(height: 10),

        SizedBox(
          height: 56,
          child: Obx(() {
            final selectedId = controller.selectedCategoryId.value;

            return ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: controller.categoryList.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final cat = controller.categoryList[i];
                final bool selected = selectedId == cat.id;

                return GestureDetector(
                  onTap: () {
                    if (selected) return;

                    controller.selectedCategoryId.value = cat.id!;
                    controller.fetchExercisesByCategory(cat.id!);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? primaryColor // 🔴 RED SELECTED
                          : Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? primaryColor : Colors.grey.shade300,
                        width: 1,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: Center(
                      child: Text(
                        cat.title ?? "",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                          fontSize: 13.5,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w600,
                          color: selected ? Colors.white : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ),

        /// 🔍 SEARCH
        Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: TextField(
            controller: searchCtrl,
            decoration: const InputDecoration(
              hintText: "Search workouts",
              prefixIcon: Icon(Icons.search),
              border: InputBorder.none,
            ),
          ),
        ),

        /// 🎬 GRID
        Expanded(
          child: Obx(() {
            /// 🟡 SHOW CATEGORY GUIDE (CLICK.JSON)
            if (filteredList.isEmpty &&
                !controller.isSyncingExercises.value &&
                controller.selectedCategoryId.value != 0) {
              return _categoryGuide();
            }

            /// 🔄 LOADING
            if (filteredList.isEmpty && controller.isSyncingExercises.value) {
              return _skeletonGrid();
            }

            /// 🎬 VIDEOS GRID
            return GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              itemCount: filteredList.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemBuilder: (_, i) => _videoCard(filteredList[i]),
            );
          }),
        ),
      ],
    );
  }

  /// 🟡 CATEGORY SELECTION GUIDE
  Widget _categoryGuide() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 200,
            child: Lottie.asset(
              "assets/click.json",
              repeat: true,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Select the category\nto watch videos",
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Tap on any category above 👆",
            style: GoogleFonts.montserrat(
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // 🎥 VIDEO CARD (PRODUCTION READY)
  // ------------------------------------------------------------

  Widget _videoCard(ExerciseItem item) {
    final thumbnail = item.thumbnailUrl ?? "";
    final isLocked = item.isLocked && !controller.isUserSubscribed.value;

    return GestureDetector(
      onTap: () {
        if (!controller.canPlayExercise(item)) {
          controller.showSubscriptionWarning();
          return;
        }

        final videoUrl = controller.resolveVideoUrl(item);
        if (videoUrl.isEmpty) return;

        Get.to(
          () => GymVideoPlayerScreen(
            title: item.title ?? "",
            trainer: "",
            videoId: videoUrl,
            thumbnail: thumbnail,
          ),
          transition: Transition.fadeIn,
          duration: const Duration(milliseconds: 220),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.network(
                thumbnail,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: Colors.grey.shade900,
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade900,
                  );
                },
              ),
            ),

            Center(
              child: Container(
                height: 54,
                width: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.55),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
                child: Icon(
                  isLocked ? Icons.lock_rounded : Icons.play_arrow_rounded,
                  size: 30,
                  color: Colors.white,
                ),
              ),
            ),

            /// PRO / FREE
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: isLocked ? Colors.redAccent : Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isLocked ? "PRO" : "FREE",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            /// TITLE
            /// TITLE
            /// TITLE
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 8, 30, 15),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.85),
                      Colors.black.withOpacity(0.0),
                    ],
                  ),
                ),
                child: Text(
                  item.exerciseTitle ?? "", // ✅ Exercise Name
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // SKELETON
  // ------------------------------------------------------------
  Widget _skeletonGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
      ),
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.grey.shade300,
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // LANGUAGE FAB
  // ------------------------------------------------------------
  Widget _languageFab() {
    return GestureDetector(
      onTap: _showLanguageBottomSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: primaryColor, // 🔴 same red
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.language,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text("Language",
                style: GoogleFonts.poppins(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showLanguageBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) => AllExercisesLanguageBottomSheet(),
    );
  }
}
