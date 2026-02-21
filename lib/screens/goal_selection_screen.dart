import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mighty_fitness/screens/diet_list_screen.dart';


class GoalSelectionScreen extends StatefulWidget {
  final String variety;
  const GoalSelectionScreen({required this.variety});

  @override
  State<GoalSelectionScreen> createState() => _GoalSelectionScreenState();
}

class _GoalSelectionScreenState extends State<GoalSelectionScreen> {
  String selectedGoal = "";

  final goals = ["Muscle Building", "Fat Loss"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        title: Text("Select Goal"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      body: Column(
        children: [
          const SizedBox(height: 40),

          ...goals.map((g) => _option(g)).toList(),

          const Spacer(),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
            ),
            onPressed: selectedGoal.isEmpty
                ? null
                : () {
                    // Get.to(() => DietFilterScreen(
                    //       initialVariety: widget.variety,
                    //       initialGoal: selectedGoal,
                    //     ));
                  },
            child: Text("Show Diet"),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _option(String text) {
    final active = selectedGoal == text;

    return GestureDetector(
      onTap: () => setState(() => selectedGoal = text),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: active ? Colors.redAccent : Colors.white12,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(active ? Icons.radio_button_checked : Icons.radio_button_off,
                color: Colors.white),
            const SizedBox(width: 12),
            Text(text, style: TextStyle(color: Colors.white, fontSize: 20)),
          ],
        ),
      ),
    );
  }
}
