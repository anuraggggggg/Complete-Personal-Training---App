// import 'package:flutter/material.dart';
// import 'package:mighty_fitness/extensions/common.dart';
// import 'package:mighty_fitness/extensions/extension_util/widget_extensions.dart';
// import 'package:mighty_fitness/extensions/shared_pref.dart';
// import 'package:mighty_fitness/screens/dashboard_screen.dart';
// import 'package:mighty_fitness/utils/app_common.dart';
// import 'package:mighty_fitness/utils/app_constants.dart';

// /// ----------- USER STORE (YOUR EXISTING STORE) -------------
// class UserStore {
//   String language = "english";

//   String fName = "";
//   String lName = "";
//   String email = "";
//   String phoneNo = "";
//   String password = "";
//   String gender = "male";
//   String goal = "";
//   String workLoc = "";
//   String level = "";
//   String workoutDaysNo = "";
//   String workoutDays = "";
//   String injuredJoints = "";
//   String medCond = "";
//   String equipments = "";
//   dynamic age;
//   dynamic height;
//   String heightUnit = "";
//   dynamic weight;
//   String weightUnit = "";

//   void setLanguage(String value) {
//     language = value;
//   }

//   void setLogin(bool v) {}
//   void setToken(String v) {}
// }

// UserStore userStore = UserStore();

// /// -------- API STUB (Replace with your real API) --------
// Future<dynamic> registerApi(req) async {
//   await Future.delayed(const Duration(seconds: 2));
//   return {"data": {"api_token": "XYZ", "id": 10}};
// }

// Future getUSerDetail(context, id) async {}

// /// ---------------------- MAIN SCREEN ------------------------------
// class SignUpStep14Component extends StatefulWidget {
//   const SignUpStep14Component({super.key});

//   @override
//   State<SignUpStep14Component> createState() => _SignUpStep14ComponentState();
// }

// class _SignUpStep14ComponentState extends State<SignUpStep14Component> {
//   ScrollController scrollController = ScrollController();
//   String selectedLang = userStore.language;
//   bool isLoading = false;

  

//  /// ----------- FINAL SIGNUP API CALL -----------
// Future<void> saveData() async {
//   hideKeyboard(context);

//   Map<String, dynamic> req = {
//     "first_name": userStore.fName,
//     "last_name": userStore.lName,
//     "username": userStore.email,
//     "email": userStore.email,
//     "password": userStore.password,
//     "user_type": "user",
//     "status": "active",
//     "phone_number": userStore.phoneNo,
//     "gender": userStore.gender.toLowerCase(),
//     "goal": userStore.goal,
//     "workout_mode": userStore.workLoc,
//     "workout_level": userStore.level,
//     "workout_days_no": userStore.workoutDaysNo,
//     "workout_days": userStore.workoutDays,
//     "has_injury": userStore.injuredJoints,
//     "joints": userStore.injuredJoints,
//     "injury_info": userStore.medCond,
//     "equpments": userStore.equipments,

//     /// ⭐ SEND LANGUAGE
//     "language": userStore.language,
//   };

//   setState(() => isLoading = true);

//   await registerApi(req).then((value) async {
//     setState(() => isLoading = false);

//     /// -------------------------
//     /// ⭐ ACTUAL TOKEN EXTRACT
//     /// -------------------------
//     String token = value["data"]["api_token"].toString();

//     /// -------------------------
//     /// ⭐ SAVE TOKEN PROPERLY
//     /// -------------------------
//     await setValue(TOKEN, token);     // Save token in SharedPreferences
//     await setValue(IS_LOGIN, true);

//     print("TOKEN SAVED => $token");
//     toast("Signup Completed!");

//     /// -------------------------
//     /// ⭐ MOVE TO DASHBOARD
//     /// -------------------------
//     DashboardScreen().launch(context, isNewTask: true);

//   }).catchError((e) {
//     setState(() => isLoading = false);
//     toast(e.toString());
//   });
// }


//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
      

//       body: SafeArea(
//         child: SingleChildScrollView(
//           controller: scrollController,
//           padding: const EdgeInsets.all(20),

//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const SizedBox(height: 25),

//               Text(
//                 "Choose your language",
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 26,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),

//               const SizedBox(height: 30),

//               _langTile("english", "English"),

//               const SizedBox(height: 20),

//               _langTile("hindi", "हिन्दी"),

//               const SizedBox(height: 80),

//               /// BUTTON
//               SizedBox(
//                 width: double.infinity,
//                 height: 55,
//                 child: ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.white,
//                     shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12)),
//                   ),
//                   onPressed: isLoading
//                       ? null
//                       : () {
//                           userStore.setLanguage(selectedLang);
//                           saveData();
//                         },
//                   child: isLoading
//                       ? const CircularProgressIndicator(color: Colors.black)
//                       : const Text(
//                           "Continue",
//                           style: TextStyle(
//                             color: Colors.black,
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                 ),
//               ),

//               const SizedBox(height: 25),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   /// -------- LANGUAGE OPTION CARD ----------
//   Widget _langTile(String value, String title) {
//     bool isSelected = selectedLang == value;

//     return InkWell(
//       onTap: () => setState(() => selectedLang = value),

//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),

//         decoration: BoxDecoration(
//           color: Colors.white, // WHITE CARD
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(
//             color: isSelected ? Colors.white : Colors.grey.shade500,
//             width: isSelected ? 2.5 : 1.2,
//           ),
//         ),

//         child: Row(
//           children: [
//             Icon(
//               isSelected ? Icons.radio_button_checked : Icons.circle_outlined,
//               color: Colors.black,
//             ),

//             const SizedBox(width: 15),

//             Text(
//               title,
//               style: const TextStyle(
//                 color: Colors.black,
//                 fontSize: 18,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
