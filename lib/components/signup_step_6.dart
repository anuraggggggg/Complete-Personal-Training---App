import 'package:flutter/material.dart';
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
    } catch (e) {
      debugPrint("Level fetch error: $e");
    }
    setState(() => isLoading = false);
  }

  // ================= SELECT LEVEL =================
  void _selectLevel(int index) {
    for (var item in levelList) {
      item.select = false;
    }

    levelList[index].select = true;

    /// ✅ SAVE LEVEL ID
    userStore.setlevel(levelList[index].id.toString());
    appStore.signUpIndex = 6;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      // backgroundColor: cs.background,
      body: isLoading
          ? Center(child: Loader(color: cs.primary))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                40.height,

                /// ================= TITLE =================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    "Choose Your Level",
                    style:
                        boldTextStyle(size: 24).copyWith(color: cs.onSurface),
                  ),
                ),

                16.height,

                /// ================= LEVEL SELECTION BUTTONS =================
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: List.generate(levelList.length, (index) {
                        final item = levelList[index];
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
                            onTap: () => _selectLevel(index),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              padding: const EdgeInsets.all(20),
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
                                    padding: const EdgeInsets.all(12),
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
                                      size: 30,
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title ?? "",
                                          style: boldTextStyle(
                                            size: 20,
                                            color: selected
                                                ? cs.primary
                                                : cs.onSurface,
                                          ),
                                        ),
                                        4.height,
                                        Text(
                                          "Optimize your workout for this level",
                                          style: secondaryTextStyle(
                                            size: 14,
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
    );
  }
}
