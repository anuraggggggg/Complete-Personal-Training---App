import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mighty_fitness/extensions/app_button.dart';
import 'package:mighty_fitness/extensions/extension_util/context_extensions.dart';
import 'package:mighty_fitness/extensions/extension_util/int_extensions.dart';
import 'package:mighty_fitness/extensions/text_styles.dart';
import 'package:mighty_fitness/main.dart';

class SignUpStep7Component extends StatefulWidget {
  const SignUpStep7Component({super.key});

  @override
  State<SignUpStep7Component> createState() => _SignUpStep7ComponentState();
}

class _SignUpStep7ComponentState extends State<SignUpStep7Component> {
  final List<int> workoutOptions = [3, 6]; // only 3 and 6 days
  int selectedIndex = 0;

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

          /// ================= TITLE =================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "How Many Days Can You Workout?",
              style: boldTextStyle(size: 22)
                  .copyWith(color: cs.onSurface),
            ),
          ),

          20.height,

          /// ================= OPTIONS =================
          Center(
            child: Wrap(
              spacing: 18,
              children: List.generate(workoutOptions.length, (index) {
                final bool selected = selectedIndex == index;

                return GestureDetector(
                  onTap: () {
                    setState(() => selectedIndex = index);
                  },
                  child: Container(
                    height: 90,
                    width: 100,
                    decoration: BoxDecoration(
                      color: selected
                          ? cs.primary
                          : (isDark
                              ? cs.surface
                              : cs.surfaceContainerHighest),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? cs.primary
                            : cs.onSurface.withOpacity(0.15),
                        width: 1.2,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: cs.primary.withOpacity(0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : [],
                    ),
                    child: Center(
                      child: Text(
                        '${workoutOptions[index]}',
                        style: TextStyle(
                          color: selected
                              ? cs.onPrimary
                              : cs.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          60.height,

          /// ================= NEXT BUTTON =================
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppButton(
              text: languages.lblNext,
              width: context.width(),
              color: cs.primary,
              onTap: () {
                userStore.setWorkoutDaysNo(
                  workoutOptions[selectedIndex],
                );
                appStore.signUpIndex = 7;

                if (kDebugMode) {
                  print(
                      "Selected workout days: ${workoutOptions[selectedIndex]}");
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
