import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'goal_selection_screen.dart';

class VarietySelectionScreen extends StatefulWidget {
  @override
  State<VarietySelectionScreen> createState() => _VarietySelectionScreenState();
}

class _VarietySelectionScreenState extends State<VarietySelectionScreen> {
  String selectedVariety = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Choose Variety"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      body: Column(
        children: [
          const SizedBox(height: 40),

          _option("Veg", "veg"),
          _option("Non-Veg", "nonveg"),

          const Spacer(),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
            ),
            onPressed: selectedVariety.isEmpty
                ? null
                : () {
                    Get.to(() => GoalSelectionScreen(variety: selectedVariety));
                  },
            child: Text("Next"),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _option(String text, String value) {
    final active = selectedVariety == value;

    return GestureDetector(
      onTap: () => setState(() => selectedVariety = value),
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
