import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mighty_fitness/controllers/workout_mode_controller/workout_mode_controller.dart';
import 'package:mighty_fitness/extensions/extension_util/int_extensions.dart';
import 'package:mighty_fitness/extensions/loader_widget.dart';
import 'package:mighty_fitness/extensions/text_styles.dart';
import 'package:mighty_fitness/main.dart';
import 'package:mighty_fitness/models/level_response.dart';
import 'package:mighty_fitness/network/rest_api.dart';

class SignUpStep6Component extends StatefulWidget {
  const SignUpStep6Component({super.key});

  @override
  State<SignUpStep6Component> createState() => _SignUpStep6ComponentState();
}

class _SignUpStep6ComponentState extends State<SignUpStep6Component> {
  List<LevelModel> levelList = [];
  bool isLoading = true;
  final WorkoutModeController workoutCtrl =
      Get.isRegistered<WorkoutModeController>()
          ? Get.find<WorkoutModeController>()
          : Get.put(WorkoutModeController());

  @override
  void initState() {
    super.initState();
    _loadLevels();
  }

  // ================= API =================
  Future<void> _loadLevels() async {
    try {
      final LevelResponse res = await getLevelListApi();
      levelList = res.data ?? [];
      final int? selectedLevelId = int.tryParse(userStore.level);
      for (final item in levelList) {
        item.select = item.id == selectedLevelId;
      }
    } catch (e) {
      debugPrint("Level fetch error: $e");
    }
    setState(() => isLoading = false);
  }

  // ================= SELECT LEVEL =================
  void _selectLevel(LevelModel selectedLevel) {
    for (var item in levelList) {
      item.select = item.id == selectedLevel.id;
    }

    /// ✅ SAVE LEVEL ID
    userStore.setlevel(selectedLevel.id.toString());
    appStore.signUpIndex = 7;

    setState(() {});
  }

  List<LevelModel> get _filteredLevels {
    final int? selectedWorkoutModeId = int.tryParse(userStore.workLoc);
    final bool isHomeSelected = selectedWorkoutModeId != null &&
        selectedWorkoutModeId == workoutCtrl.homeId.value;
    final bool isGymSelected = selectedWorkoutModeId != null &&
        selectedWorkoutModeId == workoutCtrl.gymId.value;

    bool matchesLevel(LevelModel level) {
      final String title = (level.title ?? '').toLowerCase();
      final bool isBeginner = title.contains('beginner');
      final bool isIntermediate = title.contains('intermediate');
      final bool isAdvanced = title.contains('advance');

      if (isHomeSelected) return isBeginner || isAdvanced;
      if (isGymSelected) return isBeginner || isIntermediate || isAdvanced;
      return true;
    }

    return levelList.where(matchesLevel).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final List<LevelModel> visibleLevels = _filteredLevels;

    return Scaffold(
      // backgroundColor: cs.background,
      body: isLoading
          ? Center(child: Loader(color: cs.primary))
          : SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  12.height,

                  /// ================= TITLE =================
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "Choose Your Level",
                      style:
                          boldTextStyle(size: 28).copyWith(color: cs.onSurface),
                    ),
                  ),

                  16.height,

                  /// ================= LEVEL SELECTION BUTTONS =================
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: List.generate(visibleLevels.length, (index) {
                          final item = visibleLevels[index];
                          final bool selected = item.select;

                          // Pick icon based on title
                          IconData levelIcon = Icons.fitness_center;
                          String title = (item.title ?? "").toLowerCase();
                          if (title.contains("beginner"))
                            levelIcon = Icons.accessibility_new;
                          if (title.contains("intermediate"))
                            levelIcon = Icons.bolt;
                          if (title.contains("advance"))
                            levelIcon = Icons.whatshot;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _selectLevel(item),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: selected
                                      ? cs.primary.withOpacity(0.15)
                                      : (isDark
                                          ? Colors.white.withOpacity(0.05)
                                          : Colors.black.withOpacity(0.03)),
                                  border: Border.all(
                                    color: selected
                                        ? cs.primary
                                        : (isDark
                                            ? Colors.white24
                                            : Colors.black12),
                                    width: selected ? 2 : 1,
                                  ),
                                  boxShadow: selected
                                      ? [
                                          BoxShadow(
                                            color: cs.primary.withOpacity(0.3),
                                            blurRadius: 12,
                                            offset: const Offset(0, 6),
                                          )
                                        ]
                                      : [],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? cs.primary
                                            : (isDark
                                                ? Colors.white10
                                                : Colors.black12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        levelIcon,
                                        color: selected
                                            ? Colors.white
                                            : (isDark
                                                ? Colors.white70
                                                : Colors.black54),
                                        size: 28,
                                      ),
                                    ),
                                    12.width,
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.title ?? "",
                                            style: boldTextStyle(
                                              size: 18,
                                              color: selected
                                                  ? cs.primary
                                                  : cs.onSurface,
                                            ),
                                          ),
                                          4.height,
                                          Text(
                                            "Optimize your workout for this level",
                                            style: secondaryTextStyle(
                                              size: 16,
                                              color:
                                                  cs.onSurface.withOpacity(0.6),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (selected)
                                      Icon(
                                        Icons.check_circle,
                                        color: cs.primary,
                                        size: 28,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
