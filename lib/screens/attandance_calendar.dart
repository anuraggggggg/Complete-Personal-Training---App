import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mighty_fitness/controllers/attendance_controller/attendance_controller.dart';
import 'package:mighty_fitness/controllers/circuite_exercise_controller/circuite_exercise_controller.dart';
import 'package:mighty_fitness/main.dart';
import 'package:mighty_fitness/screens/circuit_workout_screen.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:mighty_fitness/utils/app_colors.dart';

class AttendanceCalendarScreen extends StatefulWidget {
  const AttendanceCalendarScreen({super.key});

  @override
  State<AttendanceCalendarScreen> createState() =>
      _AttendanceCalendarScreenState();
}

class _AttendanceCalendarScreenState extends State<AttendanceCalendarScreen> {
  final AttendanceController controller =
      Get.isRegistered<AttendanceController>()
          ? Get.find<AttendanceController>()
          : Get.put(AttendanceController());
  final CircularWorkoutController circuitController =
      Get.find<CircularWorkoutController>();

  Worker? _attendanceWorker;
  bool _absentAlertShown = false;

  String formatMonthRange(String raw) {
    try {
      // expected: 2026-01-01 to 2026-01-31
      final parts = raw.split('to');
      if (parts.length != 2) return raw;

      final start = DateTime.parse(parts[0].trim());
      final end = DateTime.parse(parts[1].trim());

      final formatter = DateFormat('dd MMM yyyy');

      return "${formatter.format(start)} – ${formatter.format(end)}";
    } catch (e) {
      return raw; // fallback (safe)
    }
  }

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTimeRange? _selectedRange;

  String _formatDateRange(DateTimeRange range) {
    final formatter = DateFormat('dd MMM yyyy');
    return "${formatter.format(range.start)} - ${formatter.format(range.end)}";
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final first = DateTime(now.year - 2, 1, 1);
    final last = DateTime(now.year + 2, 12, 31);

    final picked = await showDateRangePicker(
      context: context,
      firstDate: first,
      lastDate: last,
      initialDateRange: _selectedRange,
      helpText: "Select Attendance Range",
      saveText: "Apply",
    );

    if (picked == null) return;

    setState(() {
      _selectedRange = picked;
      _focusedDay = picked.end;
    });

    await controller.fetchAttendance(
      force: true,
      startDate: picked.start,
      endDate: picked.end,
    );
  }

  void _showAttendanceDetails(DateTime date) {
    final details = controller.attendanceDetailsFor(date);
    if (details == null) return;

    final String subtitle =
        (details.details != null && details.details!.trim().isNotEmpty)
            ? details.details!
            : "No details";

    Get.snackbar(
      DateFormat('dd MMM yyyy').format(date),
      "${details.status ?? 'Unknown'}\n$subtitle",
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void initState() {
    super.initState();

    _attendanceWorker = ever<Map<DateTime, int>>(controller.attendanceMap, (_) {
      _showAbsentAlertIfNeeded();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showAbsentAlertIfNeeded();
      unawaited(_preloadTodayCircuitWorkout());
    });
  }

  Future<void> _preloadTodayCircuitWorkout() async {
    await circuitController.fetchCircularWorkout(
      userId: userStore.userId,
      languageId: 3,
      skipToday: 0,
      showFeedback: false,
    );
  }

  void _openCircuitWorkout() {
    Get.to(
      () => CircuitWorkoutScreen(),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 300),
    );
  }

  void _showAbsentAlertIfNeeded() {
    if (!mounted || _absentAlertShown) return;
    if (!controller.shouldShowAbsentAlert(threshold: 15)) return;

    final range = controller.absentDateRange;
    String dateRangeText = "";
    if (range != null) {
      final start = DateFormat('dd MMM').format(range.$1);
      final end = DateFormat('dd MMM yyyy').format(range.$2);
      dateRangeText = "$start - $end";
    }

    _absentAlertShown = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.warning_rounded,
                    color: Colors.red.shade400, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                "Attendance Alert",
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You were absent for 15 days.\nNow you have to do circuit exercises.',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  height: 1.5,
                  color: Colors.black54,
                ),
              ),
              if (dateRangeText.isNotEmpty) ...[
                const SizedBox(height: 20),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.date_range_rounded,
                          size: 18, color: Colors.black54),
                      const SizedBox(width: 8),
                      Text(
                        dateRangeText,
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    "I Understand",
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
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

  @override
  void dispose() {
    _attendanceWorker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Attendance Calendar",
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: cs.onSurface,
          ),
        ),
        // actions: [
        //   IconButton(
        //     tooltip: "Pick Range",
        //     onPressed: _pickDateRange,
        //     icon: const Icon(Icons.date_range),
        //   ),
        // ],
      ),

      /// 🟢 STACK FOR FAST UI + SYNC BAR
      body: Stack(
        children: [
          /// ---------------- MAIN CONTENT ----------------
          Obx(() {
            if (controller.hasError.value) {
              return Center(
                child: Text(
                  controller.errorMessage.value,
                  style: GoogleFonts.montserrat(
                    color: cs.onSurface.withOpacity(0.7),
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _summaryCard(),
                  const SizedBox(height: 12),
                  _calendar(),
                  const SizedBox(height: 16),
                  _legend(),
                  const SizedBox(height: 22),
                  _singleCircuitWorkoutCard(),
                  const SizedBox(height: 30),
                ],
              ),
            );
          }),

          /// ---------------- TOP SYNC LOADER ----------------
          Obx(() => controller.isSyncing.value
              ? const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    minHeight: 2,
                  ),
                )
              : const SizedBox()),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // 📊 SUMMARY CARD
  // ----------------------------------------------------------
  Widget _summaryCard() {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.onSurface.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _summaryTile(
            "Completed",
            controller.totalCompletedDays,
            Colors.green,
          ),
          // _summaryTile(
          //   "Range",
          //   _selectedRange != null
          //       ? _formatDateRange(_selectedRange!)
          //       : (controller.attendanceModel?.monthRange != null
          //           ? formatMonthRange(controller.attendanceModel!.monthRange!)
          //           : "-"),
          //   cs.onSurface,
          //   isText: true,
          // ),
        ],
      ),
    );
  }

  Widget _summaryTile(
    String title,
    dynamic value,
    Color color, {
    bool isText = false,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          textAlign: TextAlign.right,
          style: GoogleFonts.montserrat(
            color: cs.onSurface.withOpacity(0.65),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value.toString(),
          style: GoogleFonts.montserrat(
            color: color,
            fontSize: isText ? 14 : 26,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------------
  // 📅 CALENDAR (FAST RENDER)
  // ----------------------------------------------------------
  Widget _calendar() {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.onSurface.withOpacity(0.08)),
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: CalendarFormat.month,
        startingDayOfWeek: StartingDayOfWeek.monday,

        selectedDayPredicate: (day) =>
            _selectedDay != null && isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
          _showAttendanceDetails(selectedDay);
        },

        headerStyle: HeaderStyle(
          titleCentered: true,
          formatButtonVisible: false,
          titleTextStyle: GoogleFonts.montserrat(
            color: cs.onSurface,
            fontWeight: FontWeight.w600,
          ),
          leftChevronIcon: Icon(Icons.chevron_left, color: cs.onSurface),
          rightChevronIcon: Icon(Icons.chevron_right, color: cs.onSurface),
        ),

        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: GoogleFonts.montserrat(
            color: cs.onSurface.withOpacity(0.7),
          ),
          weekendStyle: GoogleFonts.montserrat(
            color: cs.onSurface.withOpacity(0.5),
          ),
        ),

        calendarStyle: CalendarStyle(
          defaultTextStyle: GoogleFonts.montserrat(color: cs.onSurface),
          weekendTextStyle: GoogleFonts.montserrat(color: cs.onSurface),
          outsideTextStyle: GoogleFonts.montserrat(
            color: cs.onSurface.withOpacity(0.3),
          ),
          todayDecoration: const BoxDecoration(),
          selectedDecoration: const BoxDecoration(),
          isTodayHighlighted: false,
        ),

        /// ⚡ OPTIMIZED MARKER (NO HEAVY CELL REBUILD)
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, _) {
            final key = DateTime(date.year, date.month, date.day);
            final value = controller.attendanceMap[key];
            final today = DateTime.now();
            final normalizedToday = DateTime(today.year, today.month, today.day);

            if (value == 1) {
              return Positioned(
                bottom: 6,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }
            if (value == 0 && !key.isAfter(normalizedToday)) {
              return Positioned(
                bottom: 6,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }
            return null;
          },
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // 🟢 LEGEND
  // ----------------------------------------------------------
  Widget _legend() {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _legendItem(Colors.green, "Workout Done", cs),
          const SizedBox(width: 16),
          _legendItem(Colors.red, "Absent", cs),
          const SizedBox(width: 16),
          _legendItem(primaryColor, "Today", cs),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String text, ColorScheme cs) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: GoogleFonts.montserrat(
            color: cs.onSurface.withOpacity(0.65),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------------
  // 🏋️ CIRCUIT WORKOUT CARD (UNCHANGED)
  // ----------------------------------------------------------
  Widget _singleCircuitWorkoutCard() {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withOpacity(0.12)),
      ),
      child: Obx(() {
        final workout = circuitController.todayWorkout;
        final exercisesCount = circuitController.todayExercises.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Today's Circuit Workout",
              style: GoogleFonts.montserrat(
                color: cs.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.fitness_center,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workout?.workoutName ?? "Full Body Circuit",
                      style: GoogleFonts.montserrat(
                        color: cs.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      exercisesCount > 0
                          ? "20 min • $exercisesCount exercises"
                          : "No exercises",
                      style: GoogleFonts.montserrat(
                        color: cs.onSurface.withOpacity(0.55),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: circuitController.isLoading.value
                    ? null
                    : () async {
                        if (circuitController.hasWorkout &&
                            !circuitController.isError.value) {
                          _openCircuitWorkout();
                          return;
                        }

                        await circuitController.fetchCircularWorkout(
                          userId: userStore.userId,
                          languageId: 3,
                          skipToday: 0,
                          force: true,
                        );

                        if (circuitController.isError.value) return;
                        if (!circuitController.hasWorkout) return;

                        _openCircuitWorkout();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: circuitController.isLoading.value
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        "Start Workout",
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
