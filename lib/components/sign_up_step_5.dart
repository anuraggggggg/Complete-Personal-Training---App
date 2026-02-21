import 'package:flutter/material.dart';
import 'package:mighty_fitness/network/rest_api.dart';
import '../extensions/app_button.dart';
import '../extensions/extension_util/context_extensions.dart';
import '../extensions/extension_util/int_extensions.dart';
import '../extensions/text_styles.dart';
import '../main.dart';
import '../models/body_part_response.dart';

class SignUpStep5Component extends StatefulWidget {
  const SignUpStep5Component({super.key});

  @override
  State<SignUpStep5Component> createState() => _SignUpStep5ComponentState();
}

class _SignUpStep5ComponentState extends State<SignUpStep5Component> {
  int selectedIndex = -1;
  String goal = "";
  bool isSnackbarVisible = false;

  List<BodyPartModel> bodyPartList = [];

  @override
  void initState() {
    super.initState();
    fetchBodyParts();
  }

  Future<void> fetchBodyParts() async {
    try {
      final res = await getBodyPartApi();
      setState(() {
        bodyPartList = res.data ?? [];
      });
    } catch (e) {
      debugPrint("ERROR FETCHING BODY PART LIST: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      // backgroundColor: cs.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          20.height,

          /// TITLE
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "What's Your Goal?",
              style: boldTextStyle(size: 22).copyWith(color: cs.onSurface),
            ),
          ),

          16.height,

          /// ================= GOAL SELECTION BUTTONS =================
          Expanded(
            child: bodyPartList.isEmpty
                ? Center(
                    child: CircularProgressIndicator(
                      color: cs.primary,
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: List.generate(bodyPartList.length, (index) {
                        final item = bodyPartList[index];
                        final bool selected = selectedIndex == index;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              setState(() {
                                selectedIndex = index;
                                goal = item.id.toString();
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: selected
                                    ? cs.primary.withOpacity(0.12)
                                    : (isDark
                                        ? Colors.white.withOpacity(0.05)
                                        : Colors.black.withOpacity(0.02)),
                                border: Border.all(
                                  color: selected
                                      ? cs.primary
                                      : (isDark
                                          ? Colors.white12
                                          : Colors.black12),
                                  width: selected ? 2 : 1,
                                ),
                                boxShadow: selected
                                    ? [
                                        BoxShadow(
                                          color: cs.primary.withOpacity(0.25),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        )
                                      ]
                                    : [],
                              ),
                              child: Row(
                                children: [
                                  /// Image Container
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isDark
                                          ? Colors.white10
                                          : Colors.black12,
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(28),
                                      child: Image.network(
                                        item.bodypartImage ?? "",
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Icon(
                                          Icons.fitness_center,
                                          color: selected
                                              ? cs.primary
                                              : cs.onSurface.withOpacity(0.4),
                                        ),
                                      ),
                                    ),
                                  ),
                                  20.width,
                                  Expanded(
                                    child: Text(
                                      item.title ?? "",
                                      style: boldTextStyle(
                                        size: 18,
                                        color: selected
                                            ? cs.primary
                                            : cs.onSurface,
                                      ),
                                    ),
                                  ),
                                  if (selected)
                                    Icon(
                                      Icons.check_circle,
                                      color: cs.primary,
                                      size: 26,
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

          /// BUTTON
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              child: AppButton(
                text: languages.lblNext,
                width: context.width(),
                color: cs.primary,
                onTap: () {
                  if (selectedIndex != -1) {
                    userStore.setGoal(goal);
                    appStore.signUpIndex = 5;
                  } else {
                    _showSnackBar(context, cs);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(BuildContext context, ColorScheme cs) {
    if (isSnackbarVisible) return;
    isSnackbarVisible = true;

    ScaffoldMessenger.of(context)
        .showSnackBar(
          SnackBar(
            backgroundColor: cs.primary,
            content: Text(
              "Please select a goal",
              style: TextStyle(
                color: cs.onPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        )
        .closed
        .then((_) => isSnackbarVisible = false);
  }
}
