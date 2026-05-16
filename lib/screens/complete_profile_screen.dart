import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mighty_fitness/main.dart';
import 'package:mighty_fitness/models/advance_and_begineer_model.dart';
import 'package:mighty_fitness/models/wrokout_muscle_gain_and_loss_list.dart';
import 'package:mighty_fitness/models/workout_type_list.dart';
import 'package:mighty_fitness/screens/complete_profile_reintegrated_controller.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});
  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final controller = Get.put(CompleteProfileReintegratedController());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? Colors.transparent : cs.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Complete Profile",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
        ),
      ),

      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _userCard(cs),
                const SizedBox(height: 24),
                _section("Personal Info", cs),
                _numberField("Age", controller.ageCtrl, 10, 90, cs),

                Row(
                  children: [
                    Expanded(
                      child: _numberField(
                          "Weight", controller.weightCtrl, 20, 300, cs),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _dropdown(
                          "Unit", controller.weightUnit, ["kg", "lb"], cs),
                    ),
                  ],
                ),

                Row(
                  children: [
                    Expanded(
                      child: _numberField(
                          "Height", controller.heightCtrl, 80, 250, cs),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _dropdown(
                          "Unit", controller.heightUnit, ["cm", "ft"], cs),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _section("Fitness Preferences", cs),

                Obx(() {
                  if (controller.isWorkoutLevelLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return DropdownButtonFormField<AdvanceAndBegineerData>(
                    value: controller.selectedWorkoutLevel.value,
                    decoration: _inputDecoration("Workout Level", cs),
                    dropdownColor: cs.surface,
                    style: TextStyle(color: cs.onSurface),
                    items: controller.workoutLevelList
                        .map(
                          (l) => DropdownMenuItem<AdvanceAndBegineerData>(
                            value: l,
                            child: Text(l.title ?? ''),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      controller.selectedWorkoutLevel.value = v;
                      debugPrint(
                          "LEVEL SELECTED => id: ${v?.id}, name: ${v?.title}");
                    },
                  );
                }),

                SizedBox(height: 12),

                /// GOAL
                Obx(() {
                  if (controller.isWorkoutModeLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return DropdownButtonFormField<Data>(
                    value: controller.selectedWorkoutMode.value,
                    decoration: _inputDecoration("Workout Mode", cs),
                    dropdownColor: cs.surface,
                    style: TextStyle(color: cs.onSurface),
                    items: controller.workoutModeList
                        .map(
                          (g) => DropdownMenuItem<Data>(
                            value: g,
                            child: Text(g.title ?? ''),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      controller.selectedWorkoutMode.value = v;
                      debugPrint(
                          "WORKOUT MODE SELECTED => id: ${v?.id}, name: ${v?.title}");
                    },
                  );
                }),
                const SizedBox(height: 12),

                /// GOAL (Muscle Gain / Weight Loss)
                Obx(() {
                  if (controller.isGoalLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return DropdownButtonFormField<WrokoutMuscleGainAndLossData>(
                    value: controller.selectedGoal.value,
                    decoration: _inputDecoration("Goal", cs),
                    dropdownColor: cs.surface,
                    style: TextStyle(color: cs.onSurface),
                    items: controller.goalList
                        .map(
                          (b) => DropdownMenuItem<WrokoutMuscleGainAndLossData>(
                            value: b,
                            child: Text(b.title ?? ''),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      controller.setSelectedGoal(v);
                      debugPrint(
                          "GOAL SELECTED => id: ${v?.id}, name: ${v?.title}");
                    },
                  );
                }),
                const SizedBox(height: 20),
                _workoutDaysSelector(cs),

                // const SizedBox(height: 20),
                // _section("Workout Time", cs),

                // _numberField(
                //   "Workout Time (minutes)",
                //   controller.workoutTimeCtrl,
                //   10,
                //   300,
                //   cs,
                // ),
              ],
            ),
          ),
        ),
      ),

      /// BOTTOM BUTTON
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Obx(() => SizedBox(
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: controller.submitProfile,
                  child: controller.isLoading.value
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Complete Registration",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              )),
        ),
      ),
    );
  }

  // ================= HELPERS =================

  Widget _userCard(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: cs.primary,
            child: Icon(Icons.person, color: cs.onPrimary),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${userStore.fName} ${userStore.lName}",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              Text(
                userStore.email,
                style: TextStyle(color: cs.onSurface.withOpacity(0.6)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _section(String title, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: cs.onSurface,
        ),
      ),
    );
  }

  Widget _numberField(
    String label,
    TextEditingController ctrl,
    int min,
    int max,
    ColorScheme cs,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        style: TextStyle(color: cs.onSurface),
        decoration: _inputDecoration(label, cs),
        validator: (v) {
          if (v == null || v.isEmpty) return "Required";
          final n = int.tryParse(v);
          if (n == null || n < min || n > max) {
            return "Between $min - $max";
          }
          return null;
        },
      ),
    );
  }

  Widget _dropdown(
    String label,
    RxString value,
    List<String> items,
    ColorScheme cs,
  ) {
    return Obx(() => DropdownButtonFormField<String>(
          initialValue: value.value,
          dropdownColor: cs.surface,
          decoration: _inputDecoration(label, cs),
          style: TextStyle(color: cs.onSurface),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) => value.value = v!,
        ));
  }

  InputDecoration _inputDecoration(String label, ColorScheme cs) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: cs.onSurface.withOpacity(0.6)),
      filled: true,
      fillColor: cs.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _workoutDaysSelector(ColorScheme cs) {
    final options = [3, 6];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _section("Workout Days", cs),
        const SizedBox(height: 12),
        Obx(() => Wrap(
              spacing: 18,
              children: options.map((d) {
                final selected = controller.workoutDaysCount.value == d;

                return GestureDetector(
                  onTap: () => controller.workoutDaysCount.value = d,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 90,
                    width: 100,
                    decoration: BoxDecoration(
                      color: selected ? cs.primary : cs.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color:
                            selected ? cs.primary : cs.outline.withOpacity(0.2),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        "$d",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: selected ? cs.onPrimary : cs.onSurface,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            )),
      ],
    );
  }
}
