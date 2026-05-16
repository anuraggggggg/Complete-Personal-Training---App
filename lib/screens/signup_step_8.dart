
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mighty_fitness/app_theme.dart';
import 'package:mighty_fitness/extensions/app_button.dart';
import 'package:mighty_fitness/extensions/extension_util/context_extensions.dart';
import 'package:mighty_fitness/extensions/extension_util/int_extensions.dart';
import 'package:mighty_fitness/extensions/text_styles.dart';
import 'package:mighty_fitness/main.dart';

class SignUpStep8Component extends StatefulWidget {
  const SignUpStep8Component({super.key});

  @override
  State<SignUpStep8Component> createState() => _SignUpStep8ComponentState();
}

class _SignUpStep8ComponentState extends State<SignUpStep8Component> {
  int days = userStore.workoutDaysNo.toInt(); // Number of days user can select
  List<String> daysList = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday"
  ];

  List<int> selectedIndexes = [];
    List<String> selectedDays = [] ;
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Column(
        children: [
          20.height,
          Text(
            "Select The Days You Can Workout",
            style: boldTextStyle(size: 22, color: Colors.black),
          ),
          30.height,
          Wrap(
            spacing: 15,
            runSpacing: 15,
            children: List.generate(daysList.length, (index) {
              final isSelected = selectedIndexes.contains(index);
              final canSelectMore = selectedIndexes.length < days || isSelected;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      selectedIndexes.remove(index);
                    } else if (canSelectMore) {
                      selectedIndexes.add(index);

                    }
                  });
                                      //  List<String> selectedDays = daysList[selectedIndexes[index]] as List<String>;

                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 60,
                  width: 110,
                  decoration: BoxDecoration(
                    color: isSelected ? primary :  const Color.fromARGB(255, 225, 225, 225),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: isSelected ? primary : Colors.transparent),
                  ),
                  child: Center(
                    child: Text(
                      daysList[index],
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          80.height,
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: AppButton(
              text: languages.lblNext,
              width: context.width(),
              color: primary,
              onTap: () {
              
                if (selectedIndexes.length != days) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    backgroundColor: primary,
                    content: Text("Please select exactly $days day's to continue.",style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),)));
                  // context.showSnackBar(
                  //     'Please select exactly $days day(s) to continue.');
                  return;
                }

                // Save selected days if needed
                final selectedDays =
                    selectedIndexes.map((i) => daysList[i]).toList();
            //    userStore.setWorkoutDaysList(selectedDays);

                appStore.signUpIndex = 8;
                  userStore.setWorkoutDays(selectedDays);
                  print(selectedDays);
              },
            ),
          ),
        ],
      ),
    );
  }
}
