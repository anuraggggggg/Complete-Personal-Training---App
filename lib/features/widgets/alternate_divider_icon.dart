import 'package:flutter/material.dart';
import 'package:mighty_fitness/screens/exercise_detail_screen.dart';


class AlternateDividerIcon extends StatelessWidget {
  const AlternateDividerIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      child: Center(
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
}
