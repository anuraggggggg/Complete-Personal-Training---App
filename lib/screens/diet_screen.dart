// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:mighty_fitness/controllers/diet_controllers/diet_controllers.dart';
// import 'package:mighty_fitness/controllers/translator_controller/translator_controller.dart';
// import 'package:mighty_fitness/extensions/loader_widget.dart';
// import 'package:mighty_fitness/screens/diet_detail_list_screen.dart';
// import 'package:mighty_fitness/screens/t_text.dart';

// class DietFilterScreen extends StatefulWidget {
//   const DietFilterScreen({super.key});

//   @override
//   State<DietFilterScreen> createState() => _DietFilterScreenState();
// }

// class _DietFilterScreenState extends State<DietFilterScreen>
//     with SingleTickerProviderStateMixin {
//   final DietListController controller = Get.put(DietListController());
//   final TranslatorController translator = Get.find<TranslatorController>();

//   // ---------------- FILTER DATA ----------------
//   final List<String> varieties = ["veg", "nonveg"];
//   final List<String> categories = [
//     "Weight Loss",
//     "Muscle Building",
//     "Fat Loss",
//     "General"
//   ];

//   String selectedVariety = "nonveg";
//   String selectedCategory = "Muscle Building";
//   String selectedGender = "male"; // 🔥 USER SPECIFIC

//   late AnimationController _anim;

//   // ---------------- CATEGORY → ID ----------------
//   int _mapCategoryToId(String category) {
//     switch (category) {
//       case "Weight Loss":
//         return 1;
//       case "Muscle Building":
//         return 5;
//       case "Fat Loss":
//         return 6;
//       case "General":
//         return 7;
//       default:
//         return 0;
//     }
//   }

//   // ---------------- LANGUAGE → ID ----------------
//   int _mapLanguageToId(String code) {
//     switch (code) {
//       case 'en':
//         return 1;
//       case 'hi':
//         return 2;
//       case 'ar':
//         return 3;
//       default:
//         return 1;
//     }
//   }

//   @override
//   void initState() {
//     super.initState();

//     _anim = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 600),
//     );

//     _fetchDiet();
//   }

//   // ---------------- FETCH DIET ----------------
//   void _fetchDiet() {
//     final langCode = translator.currentLang.value;
//     final languageId = _mapLanguageToId(langCode);
//     final categoryId = _mapCategoryToId(selectedCategory);

//     debugPrint("🚀 FETCH DIET");
//     debugPrint("➡ variety = $selectedVariety");
//     debugPrint("➡ category = $selectedCategory ($categoryId)");
//     debugPrint("➡ language = $langCode ($languageId)");
//     debugPrint("➡ gender = $selectedGender");

//     controller.fetchDietList(
//       variety: selectedVariety,
//       categoryId: categoryId,
//       languageId: languageId,
//       gender: selectedGender,
//     );

//     _anim.forward(from: 0);
//   }

//   @override
//   void dispose() {
//     _anim.dispose();
//     super.dispose();
//   }

//   // ---------------- UI HELPERS ----------------
//   Widget _filterChip({
//     required String label,
//     required bool active,
//     required VoidCallback onTap,
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 220),
//         margin: const EdgeInsets.only(right: 10),
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//         decoration: BoxDecoration(
//           color: active ? Colors.redAccent : Colors.transparent,
//           borderRadius: BorderRadius.circular(20),
//           border: Border.all(color: Colors.white24),
//         ),
//         child: TText(
//           label.toUpperCase(),
//           style: GoogleFonts.montserrat(
//             color: Colors.white,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _loader() =>  Center(child: Loader());

//   Widget _error(String msg) =>
//       Center(child: Text(msg, style: const TextStyle(color: Colors.redAccent)));

//   Widget _empty() => Center(
//         child: Text(
//           "No Diets Available",
//           style: GoogleFonts.montserrat(color: Colors.white54),
//         ),
//       );

//   // ---------------- UI ----------------
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF101010),
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF101010),
//         elevation: 0,
//         title: TText(
//           "🥗 Diet Plans",
//           style: GoogleFonts.montserrat(
//             color: Colors.white,
//             fontWeight: FontWeight.w700,
//             fontSize: 20,
//           ),
//         ),
//       ),
//       body: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // ---------------- VARIETY ----------------
//           _sectionTitle("Variety"),
//           _horizontalList(
//             items: varieties,
//             isActive: (v) => selectedVariety == v,
//             onTap: (v) {
//               setState(() => selectedVariety = v);
//               _fetchDiet();
//             },
//           ),

//           // ---------------- CATEGORY ----------------
//           _sectionTitle("Category"),
//           _horizontalList(
//             items: categories,
//             isActive: (c) => selectedCategory == c,
//             onTap: (c) {
//               setState(() => selectedCategory = c);
//               _fetchDiet();
//             },
//           ),

//           const SizedBox(height: 12),

//           // ---------------- DIET LIST ----------------
//           Expanded(
//             child: Obx(() {
//               if (controller.isLoading.value) return _loader();
//               if (controller.isError.value) {
//                 return _error("Failed to load diets");
//               }
//               if (controller.dietList.isEmpty) return _empty();

//               final diets = controller.dietList;

//               return ListView.builder(
//                 padding: const EdgeInsets.all(16),
//                 itemCount: diets.length,
//                 itemBuilder: (_, index) {
//                   final diet = diets[index];

//                   final anim = CurvedAnimation(
//                     parent: _anim,
//                     curve: Interval(index / diets.length, 1.0,
//                         curve: Curves.easeOut),
//                   );

//                   return FadeTransition(
//                     opacity: anim,
//                     child: SlideTransition(
//                       position: Tween<Offset>(
//                         begin: const Offset(0, 0.2),
//                         end: Offset.zero,
//                       ).animate(anim),
//                       child: DietCard(diet: diet),
//                     ),
//                   );
//                 },
//               );
//             }),
//           ),
//         ],
//       ),
//     );
//   }

//   // ---------------- SMALL HELPERS ----------------
//   Widget _sectionTitle(String text) => Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//         child: Text(
//           text,
//           style: GoogleFonts.montserrat(
//             color: Colors.white,
//             fontSize: 16,
//             fontWeight: FontWeight.w700,
//           ),
//         ),
//       );

//   Widget _horizontalList({
//     required List<String> items,
//     required bool Function(String) isActive,
//     required Function(String) onTap,
//   }) {
//     return SizedBox(
//       height: 45,
//       child: ListView(
//         scrollDirection: Axis.horizontal,
//         padding: const EdgeInsets.symmetric(horizontal: 16),
//         children: items
//             .map(
//               (item) => _filterChip(
//                 label: item,
//                 active: isActive(item),
//                 onTap: () => onTap(item),
//               ),
//             )
//             .toList(),
//       ),
//     );
//   }
// }

// // =====================================================================
// // DIET CARD
// // =====================================================================
// class DietCard extends StatelessWidget {
//   final dynamic diet;
//   const DietCard({super.key, required this.diet});

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: () {
//         HapticFeedback.lightImpact();
//         Get.to(() => DietDetailsListScreen(diet: diet));
//       },
//       child: Container(
//         margin: const EdgeInsets.only(bottom: 20),
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: const Color(0xFFAF001C),
//           borderRadius: BorderRadius.circular(22),
//           boxShadow: [
//             BoxShadow(
//               color: const Color(0xFFAF001C).withOpacity(0.4),
//               blurRadius: 18,
//               offset: const Offset(0, 8),
//             ),
//           ],
//         ),
//         child: Row(
//           children: [
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   TText(
//                     diet.title ?? "Diet Plan",
//                     style: GoogleFonts.montserrat(
//                       color: Colors.white,
//                       fontSize: 19,
//                       fontWeight: FontWeight.w800,
//                     ),
//                   ),
//                   const SizedBox(height: 6),
//                   TText(
//                     diet.categorydietTitle ?? "",
//                     style: GoogleFonts.montserrat(
//                       color: Colors.white70,
//                       fontSize: 13,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(width: 14),
//             Container(
//               width: 95,
//               height: 120,
//               decoration: BoxDecoration(
//                 color: Colors.black,
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: ClipRRect(
//                 borderRadius: BorderRadius.circular(16),
//                 child: FadeInImage.assetNetwork(
//                   placeholder: "assets/loading.gif",
//                   image: diet.dietImage ?? "",
//                   fit: BoxFit.cover,
//                   imageErrorBuilder: (_, __, ___) =>
//                       const Icon(Icons.image_not_supported,
//                           color: Colors.white54),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
