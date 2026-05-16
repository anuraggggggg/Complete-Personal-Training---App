import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mighty_fitness/screens/exercise_detail_screen.dart';
import 'package:mighty_fitness/screens/home_page_wigets/instruction_parser.dart';

class AlternateExerciseCard extends StatelessWidget {
  final String title;
  final String instruction;
  final bool active;
  final VoidCallback onTap;

  const AlternateExerciseCard({
    super.key,
    required this.title,
    required this.instruction,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final preview = parseInstruction(instruction)
        .map((step) => step.replaceFirst(RegExp(r'^\d+\.\s*'), '').trim())
        .where((step) => step.isNotEmpty)
        .take(2)
        .toList();

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        width: 161,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: active ? kAccent : const Color(0xFF141414),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.fitness_center, color: Colors.white),
            const SizedBox(height: 10),
            Text(title.toUpperCase(),
                style: GoogleFonts.montserrat(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
            const SizedBox(height: 6),
            ...preview.map(
              (e) => Text("• $e",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      GoogleFonts.montserrat(fontSize: 8, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
